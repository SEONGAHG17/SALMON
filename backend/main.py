import time
import os
import json
import base64
from typing import Optional
from contextlib import asynccontextmanager
from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client
from qdrant_client import QdrantClient
from qdrant_client.http import models

# IBM watsonx.ai 멀티모달 추론 및 임베딩 클라이언트 임포트
from ibm_watsonx_ai import Credentials
from ibm_watsonx_ai.foundation_models import ModelInference, Embeddings

# 라우터 및 스케줄러 임포트
from history import router as history_router
from calender import router as calendar_router
from map import router as map_router
from chatbot import router as chatbot_router
from setting import router as setting_router
from basetime import start_scheduler, shutdown_scheduler
import crud


# ----------------------------------------------------
# FastAPI 라이프사이클 (한국 표준시 기준 푸시 스케줄러 관리)
# ----------------------------------------------------
@asynccontextmanager
async def lifespan(app: FastAPI):
    start_scheduler()
    yield
    shutdown_scheduler()


app = FastAPI(
    title="T.Salmon API",
    version="1.0",
    lifespan=lifespan
)

# API 라우터 등록
app.include_router(history_router)
app.include_router(calendar_router)
app.include_router(map_router)
app.include_router(chatbot_router)
app.include_router(setting_router)

# ----------------------------------------------------
# DB 및 외부 AI 클라이언트 초기화
# ----------------------------------------------------
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# watsonx 자격증명 설정
WATSONX_API_KEY = os.environ.get("WATSONX_API_KEY")
WATSONX_URL = os.environ.get("WATSONX_URL", "https://us-south.ml.cloud.ibm.com")
WATSONX_PROJECT_ID = os.environ.get("WATSONX_PROJECT_ID")
credentials = Credentials(url=WATSONX_URL, api_key=WATSONX_API_KEY)

# 💡 watsonx 멀티모달 비전 모델 초기화
VISION_MODEL_ID = "meta-llama/llama-4-maverick-17b-128e-instruct-fp8"
vision_model = ModelInference(
    model_id=VISION_MODEL_ID,
    credentials=credentials,
    project_id=WATSONX_PROJECT_ID
)

# Qdrant 및 watsonx 임베딩 클라이언트
QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")
qdrant_client = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)

embedding_model_id = os.environ.get("WATSONX_EMBEDDING_MODEL_ID", "intfloat/multilingual-e5-large")


# ----------------------------------------------------
# 디바이스 토큰 등록
# ----------------------------------------------------
class DeviceTokenRequest(BaseModel):
    user_id: str = "default_user"
    fcm_token: str


@app.post("/api/v1/devices/token")
async def register_device_token(request: DeviceTokenRequest):
    try:
        supabase.table("user_devices").upsert({
            "user_id": request.user_id,
            "fcm_token": request.fcm_token
        }).execute()
        return {"status": "success", "message": "Device token registered"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"토큰 등록 실패: {str(e)}")


# ----------------------------------------------------
# 히스토리 항목 및 연결 데이터 전체 삭제
# ----------------------------------------------------
@app.delete("/api/v1/history/{item_id}")
async def delete_history_item(item_id: str):
    try:
        supabase.table("calendar_events").delete().eq("item_id", item_id).execute()
        supabase.table("map_places").delete().eq("item_id", item_id).execute()
        supabase.table("analyzed_items").delete().eq("id", item_id).execute()

        if qdrant_client:
            try:
                try:
                    point_id = int(item_id)
                except ValueError:
                    point_id = item_id
                    
                qdrant_client.delete(
                    collection_name="screenshots",
                    points_selector=models.PointIdsList(
                        points=[point_id]
                    )
                )
            except Exception as qd_err:
                print(f"⚠️ [Qdrant 삭제 건너뜀]: {qd_err}")

        return {"status": "success", "message": "데이터가 성공적으로 삭제되었습니다."}
    except Exception as e:
        print(f"❌ [삭제 실패]: {str(e)}")
        raise HTTPException(status_code=500, detail=f"데이터 삭제 중 오류가 발생했습니다: {str(e)}")


# ----------------------------------------------------
# 이미지 OCR 분석 및 파이프라인 처리
# ----------------------------------------------------
class AnalysisResponse(BaseModel):
    status: str
    image_url: str
    item_id: Optional[int] = None
    analysis: dict


@app.post("/api/v1/analyze", response_model=AnalysisResponse)
@app.post("/api/v1/analyze/", response_model=AnalysisResponse)
async def process_and_analyze_image(
    file: UploadFile = File(...),
    user_id: str = "default_user"
):
    image_url = ""
    try:
        file_bytes = await file.read()
        filename = f"screenshot_{int(time.time())}_{file.filename}"
        
        content_type = file.content_type
        if not content_type or content_type == "application/octet-stream":
            if file.filename and file.filename.lower().endswith(".png"):
                content_type = "image/png"
            else:
                content_type = "image/jpeg"
        
        # 1. Supabase Storage 업로드
        supabase.storage.from_("screenshots").upload(
            path=filename,
            file=file_bytes,
            file_options={"content-type": content_type}
        )
        image_url = supabase.storage.from_("screenshots").get_public_url(filename)
        
        user_categories = crud.get_categories_by_user(user_id)
        categories_str = " 또는 ".join(user_categories)

        # 2. 이미지 Base64 인코딩
        image_b64 = base64.b64encode(file_bytes).decode("utf-8")

        # 3. 프롬프트 및 멀티모달 페이로드 구성
        system_prompt = f"""
            너는 스마트폰 스크린샷에서 모든 텍스트(OCR)와 핵심 정보를 정밀 분석하는 올인원 AI 비서이다.
            이미지의 유형(공모전/행사, 맛집/카페/장소, 웹사이트 링크, 모바일 쿠폰/영수증, 메모 등)을 파악하고, 각 유형에 맞는 정보를 빠짐없이 구조화하라.

            [정보 추출 및 액션 매핑 가이드]
            1. 카테고리(category): {categories_str} 중 이미지 내용과 가장 일치하는 1개 선택
            2. 일정 (schedules): 
            - 접수/신청 기간, 행사 일시, 티켓 예매일, 할인 기간 등이 있는 경우 추출
            - 날짜 포맷은 반드시 'YYYY-MM-DD' 형식 (연도 없으면 기본 '2026'년, 기간은 start_date / end_date로 분리, 당일은 동일 날짜)
            3. 장소 (places): 
            - 상호명, 식당/카페명, 도로명 주소, 랜드마크, 매장 위치가 있는 경우 place_name과 address로 추출
            4. 웹 링크 (links): 
            - 화면에 보이는 http/https URL, 도메인 주소(예: bit.ly, instagram.com 등), 신청 페이지 링크 추출
            5. 액션 매핑 (action_types): 
            - schedules가 있으면 "일정등록", places가 있으면 "지도매핑", links가 있으면 "링크이동"을 리스트에 모두 추가 (해당 없으면 빈 리스트 [])
            6. 대표 데이터 (action_data): 
            - 추출된 정보 중 사용자가 바로 활용할 수 있는 대표 정보 1개 기재 (예: "마감 2026-09-08", "서울시 강남구 테헤란로 123", "https://...", "유효기간 2026-10-31")

            [출력 형식 규칙]
            - 마크다운 백틱(```json)이나 부가 설명 없이 반드시 순수 JSON 문자열만 출력하라.

            {{
            "is_valid": true,
            "error_reason": "",
            "category": "선택된 카테고리",
            "summary": "핵심 상호명 또는 내용 요약 (1~2줄)",
            "action_types": ["일정등록", "지도매핑", "링크이동 중 해당되는 것 모두"],
            "action_data": "대표 주소, 링크, 또는 마감일",
            "schedules": [
                {{
                "title": "일정/행사 명칭",
                "start_date": "YYYY-MM-DD",
                "end_date": "YYYY-MM-DD"
                }}
            ],
            "places": [
                {{"place_name": "상호명/장소명", "address": "도로명 주소 또는 위치"}}
            ],
            "links": ["추출된 URL 문자열"]
            }}
            """.strip()

        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": system_prompt
                    },
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{content_type};base64,{image_b64}"
                        }
                    }
                ]
            }
        ]
        
        analysis_data = {}
        is_success = True

        # 4. watsonx 멀티모달 분석 실행
        try:
            response = vision_model.chat(
                messages=messages,
                params={"max_tokens": 1500}
            )
            response_text = response["choices"][0]["message"]["content"].strip()
            
            if response_text.startswith("```"):
                response_text = response_text.split("```")[1]
                if response_text.startswith("json"):
                    response_text = response_text[4:]
            response_text = response_text.strip()
            
            analysis_data = json.loads(response_text)
            if analysis_data.get("is_valid") is False:
                is_success = False
        except Exception as err:
            is_success = False
            error_cat = crud.ensure_error_category(user_id)
            analysis_data = {
                "is_valid": False,
                "category": error_cat,
                "summary": f"[분석 실패] {str(err)}",
                "error_reason": f"AI 분석 오류: {str(err)}",
                "action_types": [],
                "action_data": ""
            }

        # 5. 응답 데이터 정리
        if is_success:
            category = analysis_data.get("category", "기타")
        else:
            category = crud.ensure_error_category(user_id)
            analysis_data["category"] = category

        summary = analysis_data.get("summary", "내용 요약 없음")
        schedules = analysis_data.get("schedules", []) if is_success else []
        places = analysis_data.get("places", []) if is_success else []
        links = analysis_data.get("links", []) if is_success else []
        
        action_types_list = analysis_data.get("action_types", []) if is_success else []
        if not action_types_list and is_success:
            if schedules: action_types_list.append("일정등록")
            if places: action_types_list.append("지도매핑")
            if links: action_types_list.append("링크이동")

        action_type_str = ", ".join(action_types_list) if action_types_list else "해당없음"

        action_data = analysis_data.get("action_data", "") if is_success else ""
        if not action_data and is_success:
            if places:
                action_data = places[0].get("address") or places[0].get("place_name") or ""
            elif links:
                action_data = links[0]

        # 6. DB 저장 (실패 시에도 무조건 저장하여 히스토리 노출)
        db_data = {
            "user_id": user_id,
            "image_url": image_url,
            "category": category,
            "summary": summary,
            "action_type": action_type_str,
            "action_data": action_data
        }
        db_result = supabase.table("analyzed_items").insert(db_data).execute()
        
        inserted_row = db_result.data[0]
        item_id = inserted_row["id"]
        saved_category = inserted_row["category"]
        saved_summary = inserted_row["summary"]
        saved_action_data = inserted_row["action_data"]

        # 성공 시 캘린더 등록
        if is_success and schedules:
            for sch in schedules:
                start_d = sch.get("start_date") or sch.get("date")
                if start_d:
                    calendar_event_data = {
                        "user_id": user_id,
                        "item_id": item_id,
                        "title": sch.get("title", "예정된 일정"),
                        "event_date": start_d[:10],
                        "image_url": image_url
                    }
                    supabase.table("calendar_events").insert(calendar_event_data).execute()

        # 성공 시 지도 등록
        if is_success and places:
            for pl in places:
                map_place_data = {
                    "user_id": user_id,
                    "item_id": item_id,
                    "place_name": pl.get("place_name", "장소"),
                    "address": pl.get("address", ""),
                    "image_url": image_url
                }
                supabase.table("map_places").insert(map_place_data).execute()

        # 성공 시 watsonx 임베딩 & Qdrant 업서트
        if is_success:
            try:
                text_to_embed = f"[{saved_category}] {saved_summary} | 정보: {saved_action_data}"
                embed_engine = Embeddings(
                    model_id=embedding_model_id,
                    credentials=credentials,
                    project_id=WATSONX_PROJECT_ID
                )
                vector = embed_engine.embed_documents([text_to_embed])[0]
                
                qdrant_client.upsert(
                    collection_name="screenshots",
                    points=[
                        models.PointStruct(
                            id=item_id,
                            vector=vector,
                            payload={
                                "user_id": user_id,
                                "image_url": image_url,
                                "category": saved_category,
                                "summary": saved_summary,
                                "action_data": saved_action_data
                            }
                        )
                    ]
                )
            except Exception as embed_err:
                print(f"⚠️ [임베딩/Qdrant 저장 건너뜀]: {embed_err}")
        
        analysis_data["action_type"] = action_type_str
        analysis_data["action_data"] = action_data

        return {
            "status": "success" if is_success else "fail",
            "image_url": image_url,
            "item_id": item_id,
            "analysis": analysis_data
        }

    except Exception as e:
        print(f"\n❌ [ERROR] 파이프라인 에러 발생: {str(e)}\n")
        raise HTTPException(status_code=500, detail=f"파이프라인 에러: {str(e)}")
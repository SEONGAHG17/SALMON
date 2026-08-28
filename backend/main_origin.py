import time
import os
import json
from typing import Optional
from contextlib import asynccontextmanager
from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import google.generativeai as genai
from google.api_core.exceptions import ResourceExhausted, GoogleAPICallError
from supabase import create_client, Client
from qdrant_client import QdrantClient
from qdrant_client.http import models

# 라우터 및 스케줄러 임포트
from history import router as history_router
from calender import router as calendar_router
from map import router as map_router
from chatbot import router as chatbot_router
from setting import router as setting_router
from basetime import start_scheduler, shutdown_scheduler
import crud

from ibm_watsonx_ai import Credentials
from ibm_watsonx_ai.foundation_models import Embeddings


# ----------------------------------------------------
# FastAPI 라이프사이클
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

genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
# 💡 지원 모델명 지정
model = genai.GenerativeModel('gemini-3.6-flash')

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")
qdrant_client = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)

watsonx_api_key = os.environ.get("WATSONX_API_KEY")
watsonx_url = os.environ.get("WATSONX_URL", "https://us-south.ml.cloud.ibm.com")
watsonx_project_id = os.environ.get("WATSONX_PROJECT_ID")
embedding_model_id = os.environ.get("WATSONX_EMBEDDING_MODEL_ID", "intfloat/multilingual-e5-large")

credentials = Credentials(url=watsonx_url, api_key=watsonx_api_key)


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
    """분석 데이터, 연결된 캘린더/지도 데이터, Qdrant 벡터 포인트 삭제"""
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
        
        supabase.storage.from_("screenshots").upload(
            path=filename,
            file=file_bytes,
            file_options={"content-type": content_type}
        )
        
        image_url = supabase.storage.from_("screenshots").get_public_url(filename)
        
        user_categories = crud.get_categories_by_user(user_id)
        categories_str = " 또는 ".join(user_categories)

        prompt = f"""
        너는 스마트폰 스크린샷을 정밀 분석하는 AI 비서야.
        이미지 내의 텍스트(OCR), 상호명, 도로명 주소, 날짜/기간, 상품명, 웹 링크, UI 문구를 최대한 꼼꼼하게 읽어내서 요약해.

        만약 이미지가 너무 흐릿하거나, 텍스트가 전혀 없거나, 유의미한 일정/장소/정보를 추출할 수 없는 경우에는 
        "is_valid": false 와 함께 "error_reason"에 구체적인 이유를 한글로 작성해.

        액션은 하나만 고르는 것이 아니라, 해당되는 모든 액션을 "action_types" 리스트에 담아줘 (예: ["일정등록", "지도매핑"]).

        아래 JSON 형식으로만 정확하게 응답해. 백틱(```)이나 마크다운 외 다른 말은 절대 금지.
        {{
          "is_valid": true 또는 false,
          "error_reason": "분석 실패 시 이유 (정상 분석 시 빈 문자열)",
          "category": "{categories_str} 중 택1", 
          "summary": "핵심 내용 및 상호명, 주요 정보 한 줄 요약", 
          "action_types": ["일정등록", "지도매핑", "링크이동" 중 해당하는 것 모두 포함, 없으면 빈 리스트 []],
          "action_data": "대표 참고할 링크나 주소, 날짜 정보 (없으면 빈 문자열)",
          "schedules": [
                {{
                    "title": "일정 이름 (예: 서류 접수 기간)",
                    "start_date": "YYYY-MM-DD",
                    "end_date": "YYYY-MM-DD 또는 null"
                }}
            ],
          "places": [
              {{"place_name": "장소명 또는 상호명", "address": "도로명 주소 또는 위치 설명"}}
          ],
          "links": ["추출된 URL 문자열"]
        }}
        """
        
        image_part = {
            "mime_type": content_type,
            "data": file_bytes
        }
        
        analysis_data = {}
        is_success = True

        # AI 분석 실행
        try:
            response = model.generate_content([prompt, image_part])
            response_text = response.text.strip()
            
            if response_text.startswith("```"):
                response_text = response_text.split("```")[1]
                if response_text.startswith("json"):
                    response_text = response_text[4:]
            response_text = response_text.strip()
            
            analysis_data = json.loads(response_text)
            if analysis_data.get("is_valid") is False:
                is_success = False
        except ResourceExhausted:
            is_success = False
            error_cat = crud.ensure_error_category(user_id)
            analysis_data = {
                "is_valid": False,
                "category": error_cat,
                "summary": "[분석 실패] AI API 사용량 한도가 초과되었습니다.",
                "error_reason": "AI API 사용량 한도(Quota)가 초과되었습니다.",
                "action_types": [],
                "action_data": ""
            }
        except GoogleAPICallError as api_err:
            is_success = False
            error_cat = crud.ensure_error_category(user_id)
            analysis_data = {
                "is_valid": False,
                "category": error_cat,
                "summary": f"[분석 실패] AI 서버 통신 장애: {str(api_err)}",
                "error_reason": f"AI 분석 서버 통신 장애: {str(api_err)}",
                "action_types": [],
                "action_data": ""
            }
        except Exception as err:
            is_success = False
            error_cat = crud.ensure_error_category(user_id)
            analysis_data = {
                "is_valid": False,
                "category": error_cat,
                "summary": f"[분석 실패] {str(err)}",
                "error_reason": f"분석 오류: {str(err)}",
                "action_types": [],
                "action_data": ""
            }

        # 데이터 정리
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

        # 💡 실패하더라도 DB에 무조건 저장
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

        # watsonx 임베딩 & Qdrant 업서트 (성공 시에만)
        if is_success:
            try:
                text_to_embed = f"[{saved_category}] {saved_summary} | 정보: {saved_action_data}"
                embed_engine = Embeddings(
                    model_id=embedding_model_id,
                    credentials=credentials,
                    project_id=watsonx_project_id
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

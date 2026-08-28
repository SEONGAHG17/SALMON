# ----------------------------------------------------
# _tokenize_question과 _pick_relevant_items 알고리즘
# ----------------------------------------------------

import os
import re
import asyncio
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from supabase import create_client, Client
from qdrant_client import QdrantClient
from dotenv import load_dotenv

from ibm_watsonx_ai import Credentials
from ibm_watsonx_ai.foundation_models import ModelInference
from ibm_watsonx_ai.metanames import GenChatParamsMetaNames as ChatParams

load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

router = APIRouter(prefix="/api/v1/chat", tags=["Chatbot"])

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Optional[Client] = (
    create_client(SUPABASE_URL, SUPABASE_KEY)
    if SUPABASE_URL and SUPABASE_KEY
    else None
)

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")
qdrant_client = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY) if QDRANT_URL else None

watsonx_api_key = os.environ.get("WATSONX_API_KEY")
watsonx_url = os.environ.get("WATSONX_URL") or "https://us-south.ml.cloud.ibm.com"
watsonx_project_id = os.environ.get("WATSONX_PROJECT_ID")
watsonx_chat_model_id = os.environ.get("WATSONX_CHAT_MODEL_ID") or "ibm/granite-4-h-small"

credentials = Credentials(url=watsonx_url, api_key=watsonx_api_key) if watsonx_api_key else None


# 7일 지난 대화 내역 자동 삭제
def _purge_old_chat_history(user_id: str = "default_user"):
    if not supabase:
        return
    try:
        seven_days_ago = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
        supabase.table("chat_sessions").delete().eq("user_id", user_id).lt("updated_at", seven_days_ago).execute()
    except Exception as e:
        print(f"⚠️ [대화 히스토리 정리 건너뜀]: {e}")


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None
    user_id: str = "default_user"
    history: list[ChatMessage] = Field(default_factory=list)


class ChatCitation(BaseModel):
    id: Optional[Any] = None
    category: Optional[str] = None
    summary: Optional[str] = None
    action_type: Optional[str] = None
    action_data: Optional[str] = None


class ChatResponse(BaseModel):
    status: str
    reply: str
    session_id: str
    session_title: str
    provider: str
    model: str
    notice: Optional[str] = None
    citations: list[ChatCitation] = Field(default_factory=list)


def _watsonx_ready() -> bool:
    return bool(credentials and watsonx_project_id)


# ----------------------------------------------------
# 💡 팀원 제공: 질의 토큰화 및 불용어 제거 함수
# ----------------------------------------------------
def _tokenize_question(question: str) -> list[str]:
    tokens = re.findall(r"[0-9a-zA-Z가-힣]+", question.lower())
    stopwords = {
        "관련", "정보", "알려줘", "찾아줘", "정리해줘", "추천", "있어", "있나요",
        "있는", "있을까", "어디", "좀", "해줘", "보여줘", "보여", "주세요",
        "검색", "목록", "리스트", "항목", "지도", "지도에서", "바로가기",
    }
    return [token for token in tokens if len(token) > 1 and token not in stopwords]


# ----------------------------------------------------
# 💡 팀원 제공: 관련성 높은 아이템 선별 및 스코어링 함수
# ----------------------------------------------------
def _pick_relevant_items(question: str, items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    normalized_question = question.lower()
    query_tokens = _tokenize_question(question)

    category_keywords = ["맛집", "공모전", "장학금", "기프티콘", "여행", "기타"]
    action_keywords = {
        "일정": ["일정", "캘린더", "마감", "날짜"],
        "지도": ["지도", "장소", "주소", "위치", "맛집"],
        "링크": ["링크", "사이트", "url", "바로가기"],
    }

    requested_categories = [
        keyword for keyword in category_keywords
        if keyword in normalized_question
    ]
    detail_tokens = [
        token for token in query_tokens
        if token not in category_keywords
    ]
    is_specific_search = bool(requested_categories and detail_tokens)

    scored_items: list[tuple[int, dict[str, Any]]] = []

    for item in items:
        searchable_text = " ".join(
            str(item.get(key, "") or "")
            for key in ["category", "summary", "action_type", "action_data"]
        ).lower()
        item_category = str(item.get("category", "") or "").lower()

        token_hits = sum(1 for token in query_tokens if token in searchable_text)
        detail_hits = sum(1 for token in detail_tokens if token in searchable_text)
        category_hit = any(keyword in searchable_text for keyword in requested_categories)
        action_hit_count = sum(
            1
            for action_name, keywords in action_keywords.items()
            if any(keyword in normalized_question for keyword in keywords)
            and action_name in searchable_text
        )

        if is_specific_search and (
            token_hits < len(query_tokens)
            or detail_hits < len(detail_tokens)
        ):
            continue

        if requested_categories and not any(
            keyword in item_category or keyword in searchable_text
            for keyword in requested_categories
        ):
            continue

        if not query_tokens and not category_hit and not action_hit_count:
            continue

        score = token_hits * 3 + action_hit_count

        if category_hit:
            score += 4

        if requested_categories and any(
            keyword in item_category
            for keyword in requested_categories
        ):
            score += 3

        if score > 0:
            scored_items.append((score, item))

    if scored_items:
        scored_items.sort(key=lambda scored_item: scored_item[0], reverse=True)
        return [item for _, item in scored_items[:6]]

    return [] if is_specific_search or requested_categories else items[:5]


# Qdrant에 저장된 모든 스크린샷 데이터를 조회[cite: 10]
async def _get_all_qdrant_points(limit: int = 150) -> list[dict[str, Any]]:
    if not qdrant_client:
        return []
    try:
        def _fetch():
            res, _ = qdrant_client.scroll(
                collection_name="screenshots",
                limit=limit,
                with_payload=True,
                with_vectors=False
            )
            return res

        points = await asyncio.to_thread(_fetch)
        items = []
        for p in points:
            payload = p.payload or {}
            items.append({
                "id": p.id,
                "category": payload.get("category", "기타"),
                "summary": payload.get("summary", ""),
                "action_type": payload.get("action_type", ""),
                "action_data": payload.get("action_data", ""),
                "image_url": payload.get("image_url", ""),
            })
        return items
    except Exception as e:
        print(f"⚠️ [Qdrant Full Fetch Error]: {e}")
        return []


# Supabase 백업 전체 조회[cite: 10]
def _get_all_supabase_items(user_id: str, limit: int = 150) -> list[dict[str, Any]]:
    if not supabase:
        return []
    try:
        res = (
            supabase.table("analyzed_items")
            .select("id, image_url, category, summary, action_type, action_data")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return res.data or []
    except Exception:
        return []


def _format_all_context(items: list[dict[str, Any]]) -> str:
    if not items:
        return "저장된 스크린샷 데이터가 없습니다."
    
    formatted = []
    for i, it in enumerate(items):
        cat = it.get("category", "기타")
        summary = it.get("summary", "내용 없음")
        action_type = it.get("action_type", "")
        action_data = it.get("action_data", "")
        
        detail_str = f"[{i+1}] [분류: {cat}] {summary}"
        if action_type or action_data:
            detail_str += f" | 상세정보({action_type}): {action_data}"
        formatted.append(detail_str)
        
    return "\n\n".join(formatted)


def _clean_chat_history(history: list[ChatMessage]) -> list[dict[str, str]]:
    cleaned = []
    for msg in history[-8:]:
        role = msg.role if msg.role in {"user", "assistant"} else "user"
        content = msg.content.strip()
        if content:
            cleaned.append({"role": role, "content": content[:1000]})
    return cleaned


def _build_chat_messages(
    question: str,
    items: list[dict[str, Any]],
    history: list[ChatMessage],
) -> list[dict[str, str]]:
    system_prompt = """
너는 T.Salmon 앱의 전문 AI 비서이다.
아래 [선별된 관련 스크린샷 데이터]를 꼼꼼하게 전부 확인하고 분석하여 사용자의 질문에 답하라.

[답변 원칙]
1. [선별된 관련 스크린샷 데이터]에 적힌 상호명, 일정 기간, 접수 마감일, 주소, 상세 정보(action_data)를 최대한 구체적으로 답변에 명시한다.
2. 질문과 관련된 항목이 여러 개라면 항목별로 깔끔하게 정리하여 모두 안내한다.
3. 만약 저장된 데이터에 전혀 없는 내용이라면, 저장된 데이터에 없음을 안내하고 친절히 일반 지식을 바탕으로 설명한다.
4. 답변은 자연스럽고 명확한 한국어로 작성한다.
""".strip()

    context = _format_all_context(items)
    messages = [{"role": "system", "content": f"{system_prompt}\n\n[선별된 관련 스크린샷 데이터]:\n{context}"}]
    messages.extend(_clean_chat_history(history))
    messages.append({"role": "user", "content": question})
    return messages


async def _ask_watsonx(messages: list[dict[str, str]]) -> str:
    if not _watsonx_ready():
        raise RuntimeError("watsonx 환경 변수가 설정되지 않았습니다.")

    chat_model = ModelInference(
        model_id=watsonx_chat_model_id,
        credentials=credentials,
        project_id=watsonx_project_id,
    )
    params = {
        ChatParams.TEMPERATURE: 0.2,
        ChatParams.MAX_TOKENS: 900,
        ChatParams.TOP_P: 0.9,
    }
    response = await asyncio.to_thread(chat_model.chat, messages=messages, params=params)
    try:
        return response["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, TypeError):
        pass
    try:
        return response["results"][0]["generated_text"].strip()
    except (KeyError, IndexError, TypeError):
        pass
    return "답변을 생성하지 못했습니다."


async def _generate_session_title(question: str, reply: str) -> str:
    if not _watsonx_ready():
        return question[:18] + ("..." if len(question) > 18 else "")
    try:
        prompt = f"질문: {question}\n답변: {reply}\n위 대화의 핵심 주제를 15자 이내의 짧은 명사형 제목으로 요약해줘. 불필요한 부사나 따옴표 없이 제목만 딱 출력해."
        messages = [{"role": "user", "content": prompt}]
        title = await _ask_watsonx(messages)
        clean_title = title.replace('"', '').replace("'", "").strip()
        return clean_title[:20] if clean_title else question[:18]
    except Exception:
        return question[:18] + ("..." if len(question) > 18 else "")


@router.post("/", response_model=ChatResponse)
async def chat_with_watsonx(request: ChatRequest):
    question = request.message.strip()
    if not question:
        raise HTTPException(status_code=400, detail="질문을 입력해주세요.")

    _purge_old_chat_history(request.user_id)

    try:
        session_id = request.session_id
        session_title = "새로운 대화"
        is_new_session = False

        if (not session_id or session_id == "null" or session_id == "") and supabase:
            now_iso = datetime.now(timezone.utc).isoformat()
            res = supabase.table("chat_sessions").insert({
                "user_id": request.user_id,
                "title": session_title,
                "created_at": now_iso,
                "updated_at": now_iso
            }).execute()
            if res.data:
                session_id = str(res.data[0]["id"])
                is_new_session = True
        elif session_id and supabase:
            s_res = supabase.table("chat_sessions").select("title").eq("id", session_id).execute()
            if s_res.data:
                session_title = s_res.data[0].get("title", "대화")

        # 1. DB/Vector DB에서 저장된 전체 데이터 조회[cite: 10]
        all_items = await _get_all_qdrant_points(limit=150)
        provider_notice = f"Qdrant 전체 데이터 연동 ({len(all_items)}건)"

        if not all_items:
            all_items = _get_all_supabase_items(request.user_id, limit=150)
            provider_notice = f"Supabase 전체 데이터 연동 ({len(all_items)}건)"

        # 2. 💡 질문 기반 관련 아이템 선별 (팀원 알고리즘 적용)
        relevant_items = _pick_relevant_items(question, all_items)
        if relevant_items:
            provider_notice += f" -> 관련 항목 {len(relevant_items)}건 선별 주입"

        # 3. 선별된 데이터로 LLM 프롬프트 구성 및 전달
        messages = _build_chat_messages(question, relevant_items, request.history)

        try:
            reply = await _ask_watsonx(messages)
            provider = "watsonx"
        except Exception as watson_error:
            reply = "저장된 스크린샷을 분석하여 답변을 생성하는 중 오류가 발생했습니다."
            provider = "local_fallback"
            provider_notice = f"Watsonx 오류: {str(watson_error)}"

        # 4. 세션 제목 생성 및 대화 내역 저장[cite: 10]
        now_iso = datetime.now(timezone.utc).isoformat()
        if (is_new_session or session_title == "새로운 대화") and supabase and session_id:
            generated_title = await _generate_session_title(question, reply)
            session_title = generated_title
            supabase.table("chat_sessions").update({
                "title": session_title,
                "updated_at": now_iso
            }).eq("id", session_id).execute()
        elif supabase and session_id:
            supabase.table("chat_sessions").update({
                "updated_at": now_iso
            }).eq("id", session_id).execute()

        if supabase and session_id:
            supabase.table("chat_messages").insert([
                {"session_id": session_id, "user_id": request.user_id, "sender": "user", "message": question, "created_at": now_iso},
                {"session_id": session_id, "user_id": request.user_id, "sender": "assistant", "message": reply, "created_at": now_iso}
            ]).execute()

        # 5. 응답 Citation 구성 (선별된 relevant_items 우선 매핑)
        citations = [
            ChatCitation(
                id=item.get("id"),
                category=item.get("category"),
                summary=item.get("summary"),
                action_type=item.get("action_type"),
                action_data=item.get("action_data"),
            )
            for item in relevant_items
        ]

        return ChatResponse(
            status="success",
            reply=reply,
            session_id=session_id or "",
            session_title=session_title,
            provider=provider,
            model=watsonx_chat_model_id,
            notice=provider_notice,
            citations=citations,
        )
    except Exception as e:
        print(f"❌ [Chat Error]: {str(e)}")
        raise HTTPException(status_code=500, detail=f"챗봇 오류: {str(e)}")


@router.get("/sessions")
async def get_chat_sessions(user_id: str = "default_user"):
    if not supabase:
        return {"sessions": []}
    _purge_old_chat_history(user_id)
    res = (
        supabase.table("chat_sessions")
        .select("id, title, created_at, updated_at")
        .eq("user_id", user_id)
        .order("updated_at", desc=True)
        .execute()
    )
    return {"sessions": res.data or []}


@router.get("/sessions/{session_id}")
async def get_session_messages(session_id: str):
    if not supabase:
        return {"messages": []}
    res = (
        supabase.table("chat_messages")
        .select("id, sender, message, created_at")
        .eq("session_id", session_id)
        .order("created_at", desc=False)
        .execute()
    )
    return {"messages": res.data or []}


@router.delete("/sessions/{session_id}")
async def delete_chat_session(session_id: str):
    if not supabase:
        return {"status": "success"}
    supabase.table("chat_sessions").delete().eq("id", session_id).execute()
    return {"status": "success", "message": "대화가 삭제되었습니다."}


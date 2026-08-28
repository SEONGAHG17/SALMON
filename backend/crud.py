import os
from typing import Optional, List, Dict, Any
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# 기본 카테고리 정의 및 기본 색상 매핑
DEFAULT_CATEGORY_INFO = [
    {"name": "맛집/장소", "color_hex": "#5AC8FA", "is_default": True},
    {"name": "맛집/여행", "color_hex": "#FF9500", "is_default": True},
    {"name": "기프티콘", "color_hex": "#AF52DE", "is_default": True},
    {"name": "장학금", "color_hex": "#34C759", "is_default": True},
    {"name": "공모전", "color_hex": "#5856D6", "is_default": True},
    {"name": "기타", "color_hex": "#8E8E93", "is_default": True},
]

DEFAULT_CATEGORIES = [item["name"] for item in DEFAULT_CATEGORY_INFO]


# ---------------------------------------------------------
# 1. 카테고리 관리 (CRUD & Color 지원)
# ---------------------------------------------------------
def get_categories_by_user(user_id: str = "default_user") -> List[str]:
    """OCR 및 AI 분석용 카테고리 이름 문자열 목록 반환"""
    try:
        res = (
            supabase.table("categories")
            .select("name")
            .or_(f"user_id.eq.system,user_id.eq.{user_id}")
            .order("id", desc=False)
            .execute()
        )
        if res.data and len(res.data) > 0:
            return [row["name"] for row in res.data]
        return DEFAULT_CATEGORIES
    except Exception:
        return DEFAULT_CATEGORIES


def get_all_category_details(user_id: str = "default_user") -> List[Dict[str, Any]]:
    """설정 화면용 카테고리 상세 정보(ID, 이름, 색상HEX, 기본여부) 반환"""
    try:
        res = (
            supabase.table("categories")
            .select("id, user_id, name, color_hex, is_default")
            .or_(f"user_id.eq.system,user_id.eq.{user_id}")
            .order("id", desc=False)
            .execute()
        )
        if res.data and len(res.data) > 0:
            return res.data
        return DEFAULT_CATEGORY_INFO
    except Exception as e:
        print(f"⚠️ [카테고리 상세 조회 실패]: {e}")
        return DEFAULT_CATEGORY_INFO


def ensure_error_category(user_id: str = "default_user") -> str:
    """사용자에게 'ERROR' 카테고리가 없으면 생성하고 반환"""
    try:
        res = (
            supabase.table("categories")
            .select("name")
            .eq("user_id", user_id)
            .eq("name", "ERROR")
            .execute()
        )
        if not res.data:
            supabase.table("categories").insert({
                "user_id": user_id,
                "name": "ERROR",
                "color_hex": "#FF3B30",
                "is_default": False
            }).execute()
    except Exception as e:
        print(f"⚠️ [ERROR 카테고리 생성 오류]: {e}")
    return "ERROR"


def add_custom_category(user_id: str, name: str, color_hex: str = "#F5535E") -> Optional[Dict[str, Any]]:
    """신규 카테고리 추가 (이름 및 색상 저장)"""
    try:
        res = supabase.table("categories").insert({
            "user_id": user_id,
            "name": name.strip(),
            "color_hex": color_hex.strip(),
            "is_default": False
        }).execute()
        return res.data[0] if res.data else None
    except Exception as e:
        print(f"⚠️ [카테고리 추가 실패]: {e}")
        return None


def update_category_color(user_id: str, category_id: int, color_hex: str) -> bool:
    """카테고리 색상(HEX) 변경 저장"""
    try:
        res = (
            supabase.table("categories")
            .update({"color_hex": color_hex})
            .eq("id", category_id)
            .or_(f"user_id.eq.system,user_id.eq.{user_id}")
            .execute()
        )
        return bool(res.data)
    except Exception as e:
        print(f"⚠️ [카테고리 색상 수정 실패]: {e}")
        return False


def delete_custom_category(user_id: str, category_id: int, category_name: str) -> bool:
    """카테고리 삭제 시 기존 연관 아이템들을 '기타'로 변경하고 DB에서 삭제"""
    try:
        # 1. 기존 분석 데이터 및 캘린더 일정을 '기타'로 안전하게 이관
        supabase.table("analyzed_items").update({"category": "기타"}).eq("user_id", user_id).eq("category", category_name).execute()
        supabase.table("calendar_events").update({"category": "기타"}).eq("user_id", user_id).eq("category", category_name).execute()

        # 2. 카테고리 테이블에서 삭제 (ID 기준)
        supabase.table("categories").delete().eq("id", category_id).or_(f"user_id.eq.system,user_id.eq.{user_id}").execute()
        return True
    except Exception as e:
        print(f"⚠️ [카테고리 삭제 실패]: {e}")
        return False


# ---------------------------------------------------------
# 2. 히스토리 / 분석 결과 CRUD
# ---------------------------------------------------------
def update_history_item(user_id: str, item_id: int, summary: Optional[str] = None, category: Optional[str] = None):
    try:
        update_data = {}
        if summary is not None:
            update_data["summary"] = summary
        if category is not None:
            update_data["category"] = category

        if not update_data:
            return None

        # 1. analyzed_items 업데이트
        res = (
            supabase.table("analyzed_items")
            .update(update_data)
            .eq("id", item_id)
            .eq("user_id", user_id)
            .execute()
        )

        # 2. 연결된 calendar_events의 category/title 동시 업데이트
        cal_update = {}
        if category is not None:
            cal_update["category"] = category
        if summary is not None:
            cal_update["title"] = summary

        if cal_update:
            supabase.table("calendar_events").update(cal_update).eq("item_id", item_id).eq("user_id", user_id).execute()

        return res.data
    except Exception as e:
        print(f"⚠️ [히스토리 수정 오류]: {e}")
        return None


def delete_history_item(user_id: str, item_id: int) -> bool:
    try:
        supabase.table("calendar_events").delete().eq("item_id", item_id).eq("user_id", user_id).execute()
        supabase.table("map_places").delete().eq("item_id", item_id).eq("user_id", user_id).execute()
        supabase.table("analyzed_items").delete().eq("id", item_id).eq("user_id", user_id).execute()
        return True
    except Exception:
        return False


def delete_all_user_history(user_id: str) -> bool:
    try:
        supabase.table("calendar_events").delete().eq("user_id", user_id).execute()
        supabase.table("map_places").delete().eq("user_id", user_id).execute()
        supabase.table("analyzed_items").delete().eq("user_id", user_id).execute()
        return True
    except Exception:
        return False


# ---------------------------------------------------------
# 3. 캘린더 CRUD
# ---------------------------------------------------------
def create_calendar_event(
    user_id: str,
    title: str,
    event_date: str,
    end_date: Optional[str] = None,
    item_id: Optional[int] = None,
    category: Optional[str] = "기타",
    image_url: Optional[str] = None
) -> bool:
    try:
        data = {
            "user_id": user_id,
            "title": title,
            "event_date": event_date,
            "end_date": end_date if end_date else event_date,
            "category": category or "기타"
        }
        if item_id:
            data["item_id"] = item_id
        if image_url:
            data["image_url"] = image_url

        supabase.table("calendar_events").insert(data).execute()
        return True
    except Exception:
        return False


def update_calendar_event(
    user_id: str,
    event_id: str,
    title: Optional[str] = None,
    event_date: Optional[str] = None,
    end_date: Optional[str] = None,
    category: Optional[str] = None
):
    try:
        update_data = {}
        if title is not None:
            update_data["title"] = title
        if event_date is not None:
            update_data["event_date"] = event_date
        if end_date is not None:
            update_data["end_date"] = end_date
        if category is not None:
            update_data["category"] = category

        # 1. 캘린더 이벤트 업데이트
        res = (
            supabase.table("calendar_events")
            .update(update_data)
            .eq("id", event_id)
            .eq("user_id", user_id)
            .execute()
        )

        # 2. item_id가 연결된 일정인 경우 analyzed_items 카테고리도 동기화
        if res.data and len(res.data) > 0:
            item_id = res.data[0].get("item_id")
            if item_id and category is not None:
                supabase.table("analyzed_items").update({"category": category}).eq("id", item_id).eq("user_id", user_id).execute()

        return res.data
    except Exception as e:
        print(f"⚠️ [캘린더 수정 오류]: {e}")
        return None


def delete_calendar_event(user_id: str, event_id: str) -> bool:
    try:
        supabase.table("calendar_events").delete().eq("id", event_id).eq("user_id", user_id).execute()
        return True
    except Exception:
        return False

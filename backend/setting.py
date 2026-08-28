import os
from datetime import datetime, timezone, timedelta
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from supabase import create_client, Client
from dotenv import load_dotenv
import crud

load_dotenv()

router = APIRouter(prefix="/api/v1/settings", tags=["settings"])

KST = timezone(timedelta(hours=9))

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


class PushSettingsModel(BaseModel):
    push_enabled: bool = True
    d_day_0: bool = True
    d_day_1: bool = True
    d_day_2: bool = True
    d_day_3: bool = True
    d_day_5: bool = True
    d_day_7: bool = True
    d_day_10: bool = True
    d_day_time: str = "09:00"
    daily_summary_enabled: bool = True
    daily_summary_time: str = "18:50"


class AddCategoryModel(BaseModel):
    name: str
    color_hex: str = "#F5535E"


class UpdateCategoryColorModel(BaseModel):
    color_hex: str


@router.get("/")
async def get_settings(user_id: str = "default_user"):
    try:
        res = (
            supabase.table("user_settings")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        if res.data:
            return {"status": "success", "settings": res.data[0]}
    except Exception:
        pass
    return {"status": "success", "settings": PushSettingsModel().model_dump()}


@router.post("/")
async def save_settings(
    settings: PushSettingsModel, user_id: str = "default_user"
):
    try:
        data = settings.model_dump()
        data["user_id"] = user_id
        supabase.table("user_settings").upsert(data).execute()
        return {"status": "success", "settings": data}
    except Exception as e:
        return {"status": "error", "message": str(e)}


# ----------------------------------------------------
# 카테고리 관리 API (조회 / 추가 / 색상수정 / 삭제)
# ----------------------------------------------------
@router.get("/categories")
async def list_categories(user_id: str = "default_user"):
    """카테고리 전체 목록 및 색상 정보 조회"""
    categories = crud.get_all_category_details(user_id)
    return {"status": "success", "categories": categories}


@router.post("/categories")
async def create_category(payload: AddCategoryModel, user_id: str = "default_user"):
    """신규 카테고리 추가"""
    created = crud.add_custom_category(user_id, payload.name, payload.color_hex)
    if created:
        return {"status": "success", "category": created}
    raise HTTPException(status_code=400, detail="카테고리 추가에 실패했습니다.")


@router.patch("/categories/{category_id}/color")
async def change_category_color(
    category_id: int, payload: UpdateCategoryColorModel, user_id: str = "default_user"
):
    """카테고리 색상 수정 저장"""
    success = crud.update_category_color(user_id, category_id, payload.color_hex)
    if success:
        return {"status": "success", "message": "색상이 성공적으로 변경되었습니다."}
    raise HTTPException(status_code=400, detail="색상 변경에 실패했습니다.")


@router.delete("/categories/{category_id}")
async def remove_category(
    category_id: int, name: str, user_id: str = "default_user"
):
    """카테고리 삭제 (기존 데이터는 '기타'로 변경)"""
    success = crud.delete_custom_category(user_id, category_id, name)
    if success:
        return {"status": "success", "message": "카테고리가 삭제되었습니다."}
    raise HTTPException(status_code=400, detail="카테고리 삭제에 실패했습니다.")


# ----------------------------------------------------
# 최근 7일 알림 내역 조회 API
# ----------------------------------------------------
@router.get("/notifications")
async def get_recent_notifications(user_id: str = "default_user"):
    try:
        now = datetime.now(KST)
        seven_days_ago = (now - timedelta(days=7)).replace(
            hour=0, minute=0, second=0, microsecond=0
        ).isoformat()

        res = (
            supabase.table("notifications")
            .select("*")
            .eq("user_id", user_id)
            .gte("created_at", seven_days_ago)
            .order("created_at", desc=True)
            .execute()
        )
        return {"status": "success", "notifications": res.data or []}
    except Exception as e:
        print(f"❌ [알림 내역 조회 실패]: {e}")
        return {"status": "error", "notifications": []}


# ----------------------------------------------------
# 알림 전체 삭제 API
# ----------------------------------------------------
@router.delete("/notifications")
async def clear_all_notifications(user_id: str = "default_user"):
    try:
        supabase.table("notifications").delete().eq("user_id", user_id).execute()
        return {"status": "success", "message": "모든 알림이 삭제되었습니다."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------------------------------------------
# 단일 알림 삭제 API
# ----------------------------------------------------
@router.delete("/notifications/{notification_id}")
async def delete_single_notification(notification_id: str, user_id: str = "default_user"):
    try:
        supabase.table("notifications").delete().eq("id", notification_id).eq("user_id", user_id).execute()
        return {"status": "success", "message": "알림이 삭제되었습니다."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# import os
# from datetime import datetime, timezone, timedelta
# from fastapi import APIRouter, HTTPException
# from pydantic import BaseModel
# from supabase import create_client, Client
# from dotenv import load_dotenv

# load_dotenv()

# router = APIRouter(prefix="/api/v1/settings", tags=["settings"])

# KST = timezone(timedelta(hours=9))

# SUPABASE_URL = os.environ.get("SUPABASE_URL")
# SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
# supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# class PushSettingsModel(BaseModel):
#     push_enabled: bool = True
#     d_day_0: bool = True
#     d_day_1: bool = True
#     d_day_2: bool = True
#     d_day_3: bool = True
#     d_day_5: bool = True
#     d_day_7: bool = True
#     d_day_10: bool = True
#     d_day_time: str = "09:00"
#     daily_summary_enabled: bool = True
#     daily_summary_time: str = "18:50"


# @router.get("/")
# async def get_settings(user_id: str = "default_user"):
#     try:
#         res = (
#             supabase.table("user_settings")
#             .select("*")
#             .eq("user_id", user_id)
#             .execute()
#         )
#         if res.data:
#             return {"status": "success", "settings": res.data[0]}
#     except Exception:
#         pass
#     return {"status": "success", "settings": PushSettingsModel().model_dump()}


# @router.post("/")
# async def save_settings(
#     settings: PushSettingsModel, user_id: str = "default_user"
# ):
#     try:
#         data = settings.model_dump()
#         data["user_id"] = user_id
#         supabase.table("user_settings").upsert(data).execute()
#         return {"status": "success", "settings": data}
#     except Exception as e:
#         return {"status": "error", "message": str(e)}


# # ----------------------------------------------------
# # 💡 최근 7일 알림 내역 조회 API
# # ----------------------------------------------------
# @router.get("/notifications")
# async def get_recent_notifications(user_id: str = "default_user"):
#     try:
#         now = datetime.now(KST)
#         seven_days_ago = (now - timedelta(days=7)).replace(
#             hour=0, minute=0, second=0, microsecond=0
#         ).isoformat()

#         res = (
#             supabase.table("notifications")
#             .select("*")
#             .eq("user_id", user_id)
#             .gte("created_at", seven_days_ago)
#             .order("created_at", desc=True)
#             .execute()
#         )
#         return {"status": "success", "notifications": res.data or []}
#     except Exception as e:
#         print(f"❌ [알림 내역 조회 실패]: {e}")
#         return {"status": "error", "notifications": []}


# # ----------------------------------------------------
# # 💡 알림 전체 삭제 API
# # ----------------------------------------------------
# @router.delete("/notifications")
# async def clear_all_notifications(user_id: str = "default_user"):
#     try:
#         supabase.table("notifications").delete().eq("user_id", user_id).execute()
#         return {"status": "success", "message": "모든 알림이 삭제되었습니다."}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))


# # ----------------------------------------------------
# # 💡 단일 알림 삭제 API
# # ----------------------------------------------------
# @router.delete("/notifications/{notification_id}")
# async def delete_single_notification(notification_id: str, user_id: str = "default_user"):
#     try:
#         supabase.table("notifications").delete().eq("id", notification_id).eq("user_id", user_id).execute()
#         return {"status": "success", "message": "알림이 삭제되었습니다."}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))

# # import os
# # from fastapi import APIRouter
# # from pydantic import BaseModel
# # from supabase import create_client, Client
# # from dotenv import load_dotenv

# # load_dotenv()

# # router = APIRouter(prefix="/api/v1/settings", tags=["settings"])

# # SUPABASE_URL = os.environ.get("SUPABASE_URL")
# # SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
# # supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# # class PushSettingsModel(BaseModel):
# #     push_enabled: bool = True
# #     d_day_0: bool = True
# #     d_day_1: bool = True
# #     d_day_2: bool = True
# #     d_day_3: bool = True
# #     d_day_5: bool = True
# #     d_day_7: bool = True
# #     d_day_10: bool = True
# #     d_day_time: str = "09:00"
# #     daily_summary_enabled: bool = True
# #     daily_summary_time: str = "18:50"


# # @router.get("/")
# # async def get_settings(user_id: str = "default_user"):
# #     try:
# #         res = (
# #             supabase.table("user_settings")
# #             .select("*")
# #             .eq("user_id", user_id)
# #             .execute()
# #         )
# #         if res.data:
# #             return {"status": "success", "settings": res.data[0]}
# #     except Exception:
# #         pass
# #     return {"status": "success", "settings": PushSettingsModel().model_dump()}


# # @router.post("/")
# # async def save_settings(
# #     settings: PushSettingsModel, user_id: str = "default_user"
# # ):
# #     try:
# #         data = settings.model_dump()
# #         data["user_id"] = user_id
# #         supabase.table("user_settings").upsert(data).execute()
# #         return {"status": "success", "settings": data}
# #     except Exception as e:
# #         return {"status": "error", "message": str(e)}
import os
from fastapi import APIRouter, HTTPException, Query, Body
from pydantic import BaseModel
from typing import Optional, List
import crud

router = APIRouter(prefix="/api/v1/history", tags=["History"])

class HistoryUpdateSchema(BaseModel):
    summary: Optional[str] = None
    category: Optional[str] = None

class CategoryCreateSchema(BaseModel):
    name: str

# 1. 히스토리 목록 조회
@router.get("/")
async def get_dashboard_history(user_id: str = "default_user", limit: int = 50):
    try:
        res = (
            crud.supabase.table("analyzed_items")
            .select("id, image_url, category, summary, action_type, action_data, created_at")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return {"status": "success", "history": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"히스토리 조회 실패: {str(e)}")

# 2. 카테고리 목록 조회
@router.get("/categories")
async def get_categories(user_id: str = "default_user"):
    categories = crud.get_categories_by_user(user_id)
    return {"status": "success", "categories": categories}

# 3. 카테고리 생성
@router.post("/categories")
async def create_category(payload: CategoryCreateSchema, user_id: str = "default_user"):
    success = crud.add_custom_category(user_id, payload.name)
    if not success:
        raise HTTPException(status_code=400, detail="카테고리 추가 실패 (중복되었거나 올바르지 않은 값)")
    return {"status": "success", "category": payload.name}

# 4. 카테고리 삭제
@router.delete("/categories/{category_name}")
async def delete_category(category_name: str, user_id: str = "default_user"):
    success = crud.delete_custom_category(user_id, category_name)
    if not success:
        raise HTTPException(status_code=400, detail="기본 카테고리는 삭제할 수 없거나 삭제에 실패했습니다.")
    return {"status": "success"}

# 5. 히스토리 단일 수정
@router.patch("/{item_id}")
async def patch_history_item(item_id: int, payload: HistoryUpdateSchema, user_id: str = "default_user"):
    updated = crud.update_history_item(user_id, item_id, summary=payload.summary, category=payload.category)
    if not updated:
        raise HTTPException(status_code=404, detail="해당 항목을 찾을 수 없거나 수정 권한이 없습니다.")
    return {"status": "success", "data": updated}

# 6. 히스토리 단일 삭제
@router.delete("/{item_id}")
async def delete_single_history(item_id: int, user_id: str = "default_user"):
    success = crud.delete_history_item(user_id, item_id)
    if not success:
        raise HTTPException(status_code=500, detail="데이터 삭제에 실패했습니다.")
    return {"status": "success", "deleted_id": item_id}

# 7. 히스토리 전체 삭제
@router.delete("/")
async def clear_all_history(user_id: str = "default_user"):
    success = crud.delete_all_user_history(user_id)
    if not success:
        raise HTTPException(status_code=500, detail="전체 데이터 삭제 실패")
    return {"status": "success"}

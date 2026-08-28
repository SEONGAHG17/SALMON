from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from supabase import create_client, Client
import os

router = APIRouter(prefix="/api/v1/map", tags=["Map"])

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class MapPlaceUpdateSchema(BaseModel):
    place_name: Optional[str] = None
    address: Optional[str] = None

@router.get("/")
async def get_map_places(user_id: str = "default_user"):
    try:
        response = (
            supabase.table("map_places")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .execute()
        )
        return {"status": "success", "places": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"장소 목록 조회 실패: {str(e)}")

@router.patch("/{place_id}")
async def update_map_place(place_id: str, payload: MapPlaceUpdateSchema, user_id: str = "default_user"):
    try:
        update_data = {}
        if payload.place_name: update_data["place_name"] = payload.place_name
        if payload.address: update_data["address"] = payload.address
        
        res = supabase.table("map_places").update(update_data).eq("id", place_id).eq("user_id", user_id).execute()
        return {"status": "success", "data": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"장소 수정 실패: {str(e)}")

@router.delete("/{place_id}")
async def delete_map_place(place_id: str, user_id: str = "default_user"):
    try:
        supabase.table("map_places").delete().eq("id", place_id).eq("user_id", user_id).execute()
        return {"status": "success", "deleted_id": place_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"장소 삭제 실패: {str(e)}")

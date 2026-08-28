import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import crud

router = APIRouter(prefix="/api/v1/calendar", tags=["Calendar"])

class CalendarCreateSchema(BaseModel):
    title: str
    event_date: str
    end_date: Optional[str] = None
    item_id: Optional[int] = None

class CalendarUpdateSchema(BaseModel):
    title: Optional[str] = None
    event_date: Optional[str] = None
    end_date: Optional[str] = None

@router.get("/")
async def get_calendar_events(user_id: str = "default_user"):
    try:
        response = (
            crud.supabase.table("calendar_events")
            .select("*")
            .eq("user_id", user_id)
            .order("event_date", desc=False)
            .execute()
        )
        return {"status": "success", "events": response.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"일정 목록 조회 실패: {str(e)}")

@router.post("/")
async def create_calendar_event(payload: CalendarCreateSchema, user_id: str = "default_user"):
    success = crud.create_calendar_event(
        user_id=user_id,
        title=payload.title,
        event_date=payload.event_date,
        end_date=payload.end_date,
        item_id=payload.item_id
    )
    if not success:
        raise HTTPException(status_code=500, detail="일정 생성 실패")
    return {"status": "success"}

@router.patch("/{event_id}")
async def update_calendar_event(event_id: str, payload: CalendarUpdateSchema, user_id: str = "default_user"):
    updated = crud.update_calendar_event(
        user_id=user_id,
        event_id=event_id,
        title=payload.title,
        event_date=payload.event_date,
        end_date=payload.end_date
    )
    if not updated:
        raise HTTPException(status_code=404, detail="일정을 찾을 수 없거나 수정 실패")
    return {"status": "success", "data": updated}

@router.delete("/{event_id}")
async def delete_calendar_event(event_id: str, user_id: str = "default_user"):
    success = crud.delete_calendar_event(user_id, event_id)
    if not success:
        raise HTTPException(status_code=500, detail="일정 삭제 실패")
    return {"status": "success", "deleted_id": event_id}

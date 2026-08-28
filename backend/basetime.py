import os
import asyncio
from datetime import datetime, timezone, timedelta
import firebase_admin
from firebase_admin import credentials, messaging
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

# 한국 표준시 (KST)
KST = timezone(timedelta(hours=9))

# Firebase 초기화
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    print("🔥 [Firebase Admin] 서비스 계정 키로 초기화 완료")

SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

_scheduler_task = None


def send_fcm_push(
    token: str,
    title: str,
    body: str,
    data_payload: dict = None,
    image_url: str = None,
    user_id: str = "default_user"
):
    """FCM 푸시 메시지 발송 및 DB 알림 테이블 저장"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=title, body=body, image=image_url
            ),
            data=data_payload or {},
            token=token,
        )
        response = messaging.send(message)
        print(f"🔔 [푸시 발송 완료] {title} -> {response}")

        # DB notifications 테이블에 발송 이력 저장
        try:
            is_summary = (data_payload or {}).get("type") == "daily_summary"
            supabase.table("notifications").insert({
                "user_id": user_id,
                "title": title,
                "body": body,
                "image_url": image_url,
                "is_daily_summary": is_summary,
                "created_at": datetime.now(KST).isoformat()
            }).execute()
        except Exception as db_err:
            print(f"⚠️ [알림 DB 저장 오류]: {db_err}")

        return response
    except Exception as e:
        print(f"❌ [푸시 발송 실패]: {e}")
        return None


def get_user_push_settings(user_id: str = "default_user") -> dict:
    """사용자 알림 설정 조회"""
    try:
        res = (
            supabase.table("user_settings")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        if res.data:
            return res.data[0]
    except Exception:
        pass

    return {
        "push_enabled": True,
        "d_day_0": True,
        "d_day_1": True,
        "d_day_2": True,
        "d_day_3": True,
        "d_day_5": True,
        "d_day_7": True,
        "d_day_10": True,
        "d_day_time": "09:00",
        "daily_summary_enabled": True,
        "daily_summary_time": "18:50",
    }


async def check_daily_summary_notifications():
    """일일 분석 요약 리포트"""
    now = datetime.now(KST)
    print(f"\n📊 [일일 분석 요약 스케줄러 실행] {now.strftime('%Y-%m-%d %H:%M:%S')}")

    devices_res = (
        supabase.table("user_devices").select("user_id, fcm_token").execute()
    )
    devices = devices_res.data or []
    print(f"📱 [일일 리포트 대상 기기 수]: {len(devices)}대")

    if not devices:
        print("⚠️ [중단] user_devices 테이블에 등록된 FCM 토큰이 없습니다!")
        return

    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
    today_end = now.replace(hour=23, minute=59, second=59, microsecond=999999).isoformat()

    for dev in devices:
        user_id = dev.get("user_id", "default_user")
        token = dev.get("fcm_token")
        if not token:
            continue

        settings = get_user_push_settings(user_id)
        if not settings.get("push_enabled", True) or not settings.get("daily_summary_enabled", True):
            continue

        count = 0
        try:
            items_res = (
                supabase.table("analyzed_items")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .gte("created_at", today_start)
                .lte("created_at", today_end)
                .execute()
            )
            count = items_res.count or 0
        except Exception as e:
            print(f"⚠️ [analyzed_items 조회 오류]: {e}")

        title = "오늘의 분석 리포트 📊"
        body = (
            f"오늘 하루 동안 총 {count}건의 이미지가 분석되었습니다."
            if count > 0
            else "오늘 새롭게 분석된 이미지가 없습니다. 새 스크린샷을 등록해보세요!"
        )

        send_fcm_push(
            token=token,
            title=title,
            body=body,
            data_payload={"type": "daily_summary", "count": str(count)},
            user_id=user_id,
        )


async def check_dday_notifications():
    """D-Day 마감 알림 점검 (D-0, D-1, D-2, D-3, D-5, D-7, D-10)"""
    now = datetime.now(KST).date()
    print(f"\n⏰ [D-Day 마감 알림 점검] 기준 날짜: {now.isoformat()}")

    # 1. 기기 목록 조회
    devices_res = (
        supabase.table("user_devices").select("user_id, fcm_token").execute()
    )
    devices = devices_res.data or []
    print(f"📱 [조회된 기기 수]: {len(devices)}대 -> {devices}")

    if not devices:
        print("⚠️ [중단] user_devices 테이블에 등록된 FCM 토큰이 없습니다!")
        return

    # 2. 캘린더 일정 조회 (end_date 또는 event_date 기준)
    events_res = (
        supabase.table("calendar_events")
        .select("*")
        .execute()
    )
    events = events_res.data or []
    print(f"📅 [조회된 전체 캘린더 일정 수]: {len(events)}개")

    for dev in devices:
        user_id = dev.get("user_id", "default_user")
        token = dev.get("fcm_token")
        if not token:
            continue

        settings = get_user_push_settings(user_id)
        if not settings.get("push_enabled", True):
            print(f"⚠️ [{user_id}] 푸시 알림 비활성화 상태")
            continue

        for ev in events:
            date_str = ev.get("end_date") or ev.get("event_date")
            if not date_str:
                continue

            try:
                # 앞 10자리(YYYY-MM-DD)만 안전하게 파싱
                event_date = datetime.strptime(str(date_str)[:10], "%Y-%m-%d").date()
            except Exception as pe:
                print(f"⚠️ 날짜 파싱 실패 ({date_str}): {pe}")
                continue

            diff_days = (event_date - now).days
            title_text = ev.get("title", "일정")
            image_url = ev.get("image_url")

            should_notify = False
            dday_label = ""

            if diff_days == 0 and settings.get("d_day_0", True):
                should_notify = True
                dday_label = "D-Day 오늘 마감"
            elif diff_days == 1 and settings.get("d_day_1", True):
                should_notify = True
                dday_label = "마감 1일 전 (D-1)"
            elif diff_days == 2 and settings.get("d_day_2", True):
                should_notify = True
                dday_label = "마감 2일 전 (D-2)"
            elif diff_days == 3 and settings.get("d_day_3", True):
                should_notify = True
                dday_label = "마감 3일 전 (D-3)"
            elif diff_days == 5 and settings.get("d_day_5", True):
                should_notify = True
                dday_label = "마감 5일 전 (D-5)"
            elif diff_days == 7 and settings.get("d_day_7", True):
                should_notify = True
                dday_label = "마감 7일 전 (D-7)"
            elif diff_days == 10 and settings.get("d_day_10", True):
                should_notify = True
                dday_label = "마감 10일 전 (D-10)"

            print(f"🔍 [일정 검사] '{title_text}' | 마감일: {event_date} | diff_days: {diff_days} | 발송 여부: {should_notify}")

            if should_notify:
                send_fcm_push(
                    token=token,
                    title=f"🚨 [{dday_label}] {title_text}",
                    body=f"'{title_text}' 마감 일정이 {diff_days}일 남았습니다!" if diff_days > 0 else f"'{title_text}' 일정이 오늘 마감됩니다!",
                    data_payload={
                        "type": "d_day",
                        "d_day": str(diff_days),
                        "event_id": str(ev.get("id")),
                    },
                    image_url=image_url,
                    user_id=user_id,
                )


# ----------------------------------------------------
# 스케줄러 자동 감시 루프
# ----------------------------------------------------
async def automatic_scheduler_loop():
    while True:
        try:
            now = datetime.now(KST)
            current_time_str = now.strftime("%H:%M")

            settings = get_user_push_settings("default_user")
            daily_summary_time = settings.get("daily_summary_time", "18:50")
            d_day_time = settings.get("d_day_time", "09:00")

            # 1. D-Day 마감 알림 시간에 발송 (해당 분의 전반부 감시)
            if current_time_str == d_day_time and now.second < 20:
                print(f"\n⏰ [자동 알림] D-Day 마감 알림 시간({d_day_time}) 도달 -> 자동 발송")
                await check_dday_notifications()
                await asyncio.sleep(20)  # 동일 분 내 중복 발송 방지

            # 2. 일일 리포트 시간에 발송
            if current_time_str == daily_summary_time and now.second < 20:
                print(f"\n⏰ [자동 알림] 일일 리포트 시간({daily_summary_time}) 도달 -> 자동 발송")
                await check_daily_summary_notifications()
                await asyncio.sleep(20)

        except Exception as e:
            print(f"⚠️ [자동 스케줄러 오류]: {e}")

        await asyncio.sleep(5)


def start_scheduler():
    global _scheduler_task
    if _scheduler_task is None:
        _scheduler_task = asyncio.create_task(automatic_scheduler_loop())
        print("🚀 [KST 스케줄러] 백그라운드 자동 푸시 알림 감시기가 가동되었습니다.")


def shutdown_scheduler():
    global _scheduler_task
    if _scheduler_task:
        _scheduler_task.cancel()
        _scheduler_task = None
        print("🛑 [KST 스케줄러] 스케줄러가 종료되었습니다.")

# import os
# import asyncio
# from datetime import datetime, timezone, timedelta
# import firebase_admin
# from firebase_admin import credentials, messaging
# from supabase import create_client, Client
# from dotenv import load_dotenv

# load_dotenv()

# # 한국 표준시 (KST)
# KST = timezone(timedelta(hours=9))

# # Firebase 초기화
# if not firebase_admin._apps:
#     cred = credentials.Certificate("serviceAccountKey.json")
#     firebase_admin.initialize_app(cred)
#     print("🔥 [Firebase Admin] 서비스 계정 키로 초기화 완료")

# SUPABASE_URL = os.environ.get("SUPABASE_URL")
# SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
# supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# _scheduler_task = None


# def send_fcm_push(
#     token: str,
#     title: str,
#     body: str,
#     data_payload: dict = None,
#     image_url: str = None,
#     user_id: str = "default_user"
# ):
#     """FCM 푸시 메시지 발송 및 DB 알림 테이블 저장"""
#     try:
#         message = messaging.Message(
#             notification=messaging.Notification(
#                 title=title, body=body, image=image_url
#             ),
#             data=data_payload or {},
#             token=token,
#         )
#         response = messaging.send(message)
#         print(f"🔔 [푸시 발송 완료] {title} -> {response}")

#         # 💡 DB notifications 테이블에 발송 이력 저장
#         try:
#             is_summary = (data_payload or {}).get("type") == "daily_summary"
#             supabase.table("notifications").insert({
#                 "user_id": user_id,
#                 "title": title,
#                 "body": body,
#                 "image_url": image_url,
#                 "is_daily_summary": is_summary,
#                 "created_at": datetime.now(KST).isoformat()
#             }).execute()
#         except Exception as db_err:
#             print(f"⚠️ [알림 DB 저장 오류]: {db_err}")

#         return response
#     except Exception as e:
#         print(f"❌ [푸시 발송 실패]: {e}")
#         return None


# def get_user_push_settings(user_id: str = "default_user") -> dict:
#     """사용자 알림 설정 조회"""
#     try:
#         res = (
#             supabase.table("user_settings")
#             .select("*")
#             .eq("user_id", user_id)
#             .execute()
#         )
#         if res.data:
#             return res.data[0]
#     except Exception:
#         pass

#     return {
#         "push_enabled": True,
#         "d_day_0": True,
#         "d_day_1": True,
#         "d_day_2": True,
#         "d_day_3": True,
#         "d_day_5": True,
#         "d_day_7": True,
#         "d_day_10": True,
#         "d_day_time": "09:00",
#         "daily_summary_enabled": True,
#         "daily_summary_time": "18:50",
#     }


# async def check_daily_summary_notifications():
#     """일일 분석 요약 리포트"""
#     now = datetime.now(KST)
#     print(f"\n📊 [일일 분석 요약 스케줄러 실행] {now.strftime('%Y-%m-%d %H:%M:%S')}")

#     devices_res = (
#         supabase.table("user_devices").select("user_id, fcm_token").execute()
#     )
#     devices = devices_res.data or []

#     if not devices:
#         return

#     today_start = now.replace(hour=0, minute=0, second=0, microsecond=0).isoformat()
#     today_end = now.replace(hour=23, minute=59, second=59, microsecond=999999).isoformat()

#     for dev in devices:
#         user_id = dev.get("user_id", "default_user")
#         token = dev.get("fcm_token")
#         if not token:
#             continue

#         settings = get_user_push_settings(user_id)
#         if not settings.get("push_enabled", True) or not settings.get("daily_summary_enabled", True):
#             continue

#         count = 0
#         try:
#             items_res = (
#                 supabase.table("analyzed_items")
#                 .select("id", count="exact")
#                 .eq("user_id", user_id)
#                 .gte("created_at", today_start)
#                 .lte("created_at", today_end)
#                 .execute()
#             )
#             count = items_res.count or 0
#         except Exception as e:
#             print(f"⚠️ [analyzed_items 조회 오류]: {e}")

#         title = "오늘의 분석 리포트 📊"
#         body = (
#             f"오늘 하루 동안 총 {count}건의 이미지가 분석되었습니다."
#             if count > 0
#             else "오늘 새롭게 분석된 이미지가 없습니다. 새 스크린샷을 등록해보세요!"
#         )

#         send_fcm_push(
#             token=token,
#             title=title,
#             body=body,
#             data_payload={"type": "daily_summary", "count": str(count)},
#             user_id=user_id,
#         )


# async def check_dday_notifications():
#     """D-Day 마감 알림 점검"""
#     now = datetime.now(KST).date()
#     print(f"\n⏰ [D-Day 마감 알림 점검] {now.isoformat()}")

#     devices_res = (
#         supabase.table("user_devices").select("user_id, fcm_token").execute()
#     )
#     devices = devices_res.data or []

#     for dev in devices:
#         user_id = dev.get("user_id", "default_user")
#         token = dev.get("fcm_token")
#         if not token:
#             continue

#         settings = get_user_push_settings(user_id)
#         if not settings.get("push_enabled", True):
#             continue

#         events_res = (
#             supabase.table("calendar_events")
#             .select("*")
#             .eq("user_id", user_id)
#             .gte("event_date", now.isoformat())
#             .execute()
#         )
#         events = events_res.data or []

#         for ev in events:
#             date_str = ev.get("event_date")
#             if not date_str:
#                 continue

#             try:
#                 event_date = datetime.strptime(date_str, "%Y-%m-%d").date()
#             except Exception:
#                 continue

#             diff_days = (event_date - now).days
#             title_text = ev.get("title", "일정")
#             image_url = ev.get("image_url")

#             should_notify = False
#             dday_label = ""

#             if diff_days == 0 and settings.get("d_day_0", True):
#                 should_notify = True
#                 dday_label = "D-Day 오늘 마감"
#             elif diff_days == 1 and settings.get("d_day_1", True):
#                 should_notify = True
#                 dday_label = "마감 1일 전 (D-1)"
#             elif diff_days == 2 and settings.get("d_day_2", True):
#                 should_notify = True
#                 dday_label = "마감 2일 전 (D-2)"
#             elif diff_days == 3 and settings.get("d_day_3", True):
#                 should_notify = True
#                 dday_label = "마감 3일 전 (D-3)"
#             elif diff_days == 5 and settings.get("d_day_5", True):
#                 should_notify = True
#                 dday_label = "마감 5일 전 (D-5)"
#             elif diff_days == 7 and settings.get("d_day_7", True):
#                 should_notify = True
#                 dday_label = "마감 7일 전 (D-7)"
#             elif diff_days == 10 and settings.get("d_day_10", True):
#                 should_notify = True
#                 dday_label = "마감 10일 전 (D-10)"

#             if should_notify:
#                 send_fcm_push(
#                     token=token,
#                     title=f"🚨 [{dday_label}] {title_text}",
#                     body=f"'{title_text}' 마감 일정이 {diff_days}일 남았습니다!",
#                     data_payload={
#                         "type": "d_day",
#                         "d_day": str(diff_days),
#                         "event_id": str(ev.get("id")),
#                     },
#                     image_url=image_url,
#                     user_id=user_id,
#                 )


# async def automatic_scheduler_loop():
#     while True:
#         try:
#             now = datetime.now(KST)
#             current_time_str = now.strftime("%H:%M")

#             settings = get_user_push_settings("default_user")
#             daily_summary_time = settings.get("daily_summary_time", "18:50")
#             d_day_time = settings.get("d_day_time", "09:00")

#             if current_time_str == d_day_time and now.second < 10:
#                 print(f"⏰ [자동 알림] D-Day 마감 알림 시간({d_day_time}) 도달 -> 자동 발송")
#                 await check_dday_notifications()

#             if current_time_str == daily_summary_time and now.second < 10:
#                 print(f"⏰ [자동 알림] 일일 리포트 시간({daily_summary_time}) 도달 -> 자동 발송")
#                 await check_daily_summary_notifications()

#         except Exception as e:
#             print(f"⚠️ [자동 스케줄러 오류]: {e}")

#         await asyncio.sleep(10)


# def start_scheduler():
#     global _scheduler_task
#     if _scheduler_task is None:
#         _scheduler_task = asyncio.create_task(automatic_scheduler_loop())
#         print("🚀 [KST 스케줄러] 백그라운드 자동 푸시 알림 감시기가 가동되었습니다.")


# def shutdown_scheduler():
#     global _scheduler_task
#     if _scheduler_task:
#         _scheduler_task.cancel()
#         _scheduler_task = None
#         print("🛑 [KST 스케줄러] 스케줄러가 종료되었습니다.")

# # import os
# # import asyncio
# # from datetime import datetime, timezone, timedelta
# # import firebase_admin
# # from firebase_admin import credentials, messaging
# # from supabase import create_client, Client
# # from dotenv import load_dotenv

# # load_dotenv()

# # # 한국 표준시 (KST)
# # KST = timezone(timedelta(hours=9))

# # # Firebase 초기화
# # if not firebase_admin._apps:
# #     cred = credentials.Certificate("serviceAccountKey.json")
# #     firebase_admin.initialize_app(cred)
# #     print("🔥 [Firebase Admin] 서비스 계정 키로 초기화 완료")

# # SUPABASE_URL = os.environ.get("SUPABASE_URL")
# # SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
# # supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# # _scheduler_task = None


# # def send_fcm_push(
# #     token: str,
# #     title: str,
# #     body: str,
# #     data_payload: dict = None,
# #     image_url: str = None,
# # ):
# #     """FCM 푸시 메시지 발송 함수"""
# #     try:
# #         message = messaging.Message(
# #             notification=messaging.Notification(
# #                 title=title, body=body, image=image_url
# #             ),
# #             data=data_payload or {},
# #             token=token,
# #         )
# #         response = messaging.send(message)
# #         print(f"🔔 [푸시 발송 완료] {title} -> {response}")
# #         return response
# #     except Exception as e:
# #         print(f"❌ [푸시 발송 실패]: {e}")
# #         return None


# # def get_user_push_settings(user_id: str = "default_user") -> dict:
# #     """사용자 알림 설정 조회"""
# #     try:
# #         res = (
# #             supabase.table("user_settings")
# #             .select("*")
# #             .eq("user_id", user_id)
# #             .execute()
# #         )
# #         if res.data:
# #             return res.data[0]
# #     except Exception:
# #         pass

# #     return {
# #         "push_enabled": True,
# #         "d_day_0": True,
# #         "d_day_1": True,
# #         "d_day_2": True,
# #         "d_day_3": True,
# #         "d_day_5": True,
# #         "d_day_7": True,
# #         "d_day_10": True,
# #         "d_day_time": "09:00",
# #         "daily_summary_enabled": True,
# #         "daily_summary_time": "18:50",
# #     }


# # async def check_daily_summary_notifications():
# #     """일일 분석 요약 리포트"""
# #     now = datetime.now(KST)
# #     print(
# #         f"\n📊 [일일 분석 요약 스케줄러 실행] {now.strftime('%Y-%m-%d %H:%M:%S')}"
# #     )

# #     devices_res = (
# #         supabase.table("user_devices").select("user_id, fcm_token").execute()
# #     )
# #     devices = devices_res.data or []

# #     if not devices:
# #         return

# #     today_start = now.replace(
# #         hour=0, minute=0, second=0, microsecond=0
# #     ).isoformat()
# #     today_end = now.replace(
# #         hour=23, minute=59, second=59, microsecond=999999
# #     ).isoformat()

# #     count = 0
# #     try:
# #         items_res = (
# #             supabase.table("analyzed_items")
# #             .select("id", count="exact")
# #             .gte("created_at", today_start)
# #             .lte("created_at", today_end)
# #             .execute()
# #         )
# #         count = items_res.count or 0
# #     except Exception as e:
# #         print(f"⚠️ [analyzed_items 조회 오류]: {e}")

# #     for dev in devices:
# #         user_id = dev.get("user_id", "default_user")
# #         token = dev.get("fcm_token")
# #         if not token:
# #             continue

# #         settings = get_user_push_settings(user_id)
# #         if not settings.get("push_enabled", True):
# #             continue
# #         if not settings.get("daily_summary_enabled", True):
# #             continue

# #         title = "오늘의 분석 리포트 📊"
# #         body = (
# #             f"오늘 하루 동안 총 {count}건의 이미지가 분석되었습니다."
# #             if count > 0
# #             else "오늘 새롭게 분석된 이미지가 없습니다. 새 스크린샷을 등록해보세요!"
# #         )

# #         send_fcm_push(
# #             token=token,
# #             title=title,
# #             body=body,
# #             data_payload={"type": "daily_summary", "count": str(count)},
# #         )


# # async def check_dday_notifications():
# #     """D-Day 마감 알림 점검 (D-0, D-1, D-2, D-3, D-5, D-7, D-10)"""
# #     now = datetime.now(KST).date()
# #     print(f"\n⏰ [D-Day 마감 알림 점검] {now.isoformat()}")

# #     devices_res = (
# #         supabase.table("user_devices").select("user_id, fcm_token").execute()
# #     )
# #     devices = devices_res.data or []

# #     events_res = (
# #         supabase.table("calendar_events")
# #         .select("*")
# #         .gte("event_date", now.isoformat())
# #         .execute()
# #     )
# #     events = events_res.data or []

# #     for dev in devices:
# #         user_id = dev.get("user_id", "default_user")
# #         token = dev.get("fcm_token")
# #         if not token:
# #             continue

# #         settings = get_user_push_settings(user_id)
# #         if not settings.get("push_enabled", True):
# #             continue

# #         for ev in events:
# #             date_str = ev.get("event_date")
# #             if not date_str:
# #                 continue

# #             try:
# #                 event_date = datetime.strptime(date_str, "%Y-%m-%d").date()
# #             except Exception:
# #                 continue

# #             diff_days = (event_date - now).days
# #             title_text = ev.get("title", "일정")
# #             image_url = ev.get("image_url")

# #             should_notify = False
# #             dday_label = ""

# #             if diff_days == 0 and settings.get("d_day_0", True):
# #                 should_notify = True
# #                 dday_label = "D-Day 오늘 마감"
# #             elif diff_days == 1 and settings.get("d_day_1", True):
# #                 should_notify = True
# #                 dday_label = "마감 1일 전 (D-1)"
# #             elif diff_days == 2 and settings.get("d_day_2", True):
# #                 should_notify = True
# #                 dday_label = "마감 2일 전 (D-2)"
# #             elif diff_days == 3 and settings.get("d_day_3", True):
# #                 should_notify = True
# #                 dday_label = "마감 3일 전 (D-3)"
# #             elif diff_days == 5 and settings.get("d_day_5", True):
# #                 should_notify = True
# #                 dday_label = "마감 5일 전 (D-5)"
# #             elif diff_days == 7 and settings.get("d_day_7", True):
# #                 should_notify = True
# #                 dday_label = "마감 7일 전 (D-7)"
# #             elif diff_days == 10 and settings.get("d_day_10", True):
# #                 should_notify = True
# #                 dday_label = "마감 10일 전 (D-10)"

# #             if should_notify:
# #                 send_fcm_push(
# #                     token=token,
# #                     title=f"🚨 [{dday_label}] {title_text}",
# #                     body=f"'{title_text}' 마감 일정이 {diff_days}일 남았습니다!",
# #                     data_payload={
# #                         "type": "d_day",
# #                         "d_day": str(diff_days),
# #                         "event_id": str(ev.get("id")),
# #                     },
# #                     image_url=image_url,
# #                 )


# # # ----------------------------------------------------
# # # 💡 스케줄러 자동 감시 루프 (설정 시간 일치 시 자동 발송)
# # # ----------------------------------------------------
# # async def automatic_scheduler_loop():
# #     while True:
# #         try:
# #             now = datetime.now(KST)
# #             current_time_str = now.strftime("%H:%M")

# #             settings = get_user_push_settings("default_user")
# #             daily_summary_time = settings.get("daily_summary_time", "18:50")
# #             d_day_time = settings.get("d_day_time", "09:00")

# #             # 1. 사용자가 맞춤 설정한 D-Day 알림 시간에 발송
# #             if current_time_str == d_day_time and now.second < 10:
# #                 print(
# #                     f"⏰ [자동 알림] D-Day 마감 알림 시간({d_day_time}) 도달 -> 자동 발송"
# #                 )
# #                 await check_dday_notifications()

# #             # 2. 사용자가 맞춤 설정한 일일 리포트 시간에 발송
# #             if current_time_str == daily_summary_time and now.second < 10:
# #                 print(
# #                     f"⏰ [자동 알림] 일일 리포트 시간({daily_summary_time}) 도달 -> 자동 발송"
# #                 )
# #                 await check_daily_summary_notifications()

# #         except Exception as e:
# #             print(f"⚠️ [자동 스케줄러 오류]: {e}")

# #         await asyncio.sleep(10)


# # def start_scheduler():
# #     global _scheduler_task
# #     if _scheduler_task is None:
# #         _scheduler_task = asyncio.create_task(automatic_scheduler_loop())
# #         print("🚀 [KST 스케줄러] 백그라운드 자동 푸시 알림 감시기가 가동되었습니다.")


# # def shutdown_scheduler():
# #     global _scheduler_task
# #     if _scheduler_task:
# #         _scheduler_task.cancel()
# #         _scheduler_task = None
# #         print("🛑 [KST 스케줄러] 스케줄러가 종료되었습니다.")
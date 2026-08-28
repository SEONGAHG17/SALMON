import os
from datetime import datetime, timedelta, timezone
import firebase_admin
from firebase_admin import credentials, messaging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

# 한국 표준시 (KST, UTC+9)
KST = timezone(timedelta(hours=9))

def get_korean_now():
    return datetime.now(KST)

# Supabase 클라이언트 초기화
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Firebase Admin SDK 절대 경로 기반 초기화
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH", os.path.join(BASE_DIR, "serviceAccountKey.json"))

if not firebase_admin._apps:
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print("✅ [Firebase Admin] 초기화 성공")
    else:
        print(f"⚠️ [Firebase Admin] 키 파일을 찾을 수 없습니다: {cred_path}")

scheduler = AsyncIOScheduler()

async def send_and_save_notification(user_id: str, title: str, body: str, is_daily_summary: bool = False, image_url: str = None):
    """
    1. Supabase notifications 테이블에 알림 영구 저장
    2. user_devices 테이블의 기기 토큰으로 실시간 FCM 푸시 발송
    """
    now_kst_str = get_korean_now().isoformat()

    # 1. Supabase notifications 테이블 기록
    try:
        supabase.table("notifications").insert({
            "user_id": user_id,
            "title": title,
            "body": body,
            "is_daily_summary": is_daily_summary,
            "image_url": image_url,
            "created_at": now_kst_str
        }).execute()
        print(f"📝 [DB 저장 완료] {title}")
    except Exception as e:
        print(f"❌ [DB 알림 저장 실패]: {e}")

    # 2. 유저 등록 기기 FCM 발송
    try:
        devices = supabase.table("user_devices").select("fcm_token").eq("user_id", user_id).execute()
        tokens = [row["fcm_token"] for row in (devices.data or []) if row.get("fcm_token")]

        for token in tokens:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={
                    "title": title,
                    "body": body,
                    "is_daily_summary": "true" if is_daily_summary else "false"
                },
                token=token,
            )
            response = messaging.send(message)
            print(f"🔔 [FCM 발송 성공] ID: {response}")
    except Exception as e:
        print(f"❌ [FCM 발송 실패]: {e}")


# 작업 1: 💡 D-Day 마감 임박 알림 체크 (D-Day, D-1, D-2, D-3, D-5, D-7, D-10)
async def check_deadline_notifications():
    now_kst = get_korean_now()
    today = now_kst.date()
    print(f"⏰ [스케줄러 실행] 마감 임박 일정 체크 ({today.strftime('%Y-%m-%d')})")

    try:
        # 유저 설정 조회
        settings_res = supabase.table("user_settings").select("*").eq("user_id", "default_user").execute()
        settings = settings_res.data[0] if settings_res.data else {}

        if not settings.get("push_enabled", True):
            print("ℹ️ [알림 스킵] 유저 푸시 알림이 꺼져 있습니다.")
            return

        # 오늘 이후의 모든 캘린더 일정 조회
        events_res = supabase.table("calendar_events").select("*").eq("user_id", "default_user").gte("event_date", today.strftime('%Y-%m-%d')).execute()
        events = events_res.data or []

        for ev in events:
            ev_date_str = ev.get("event_date")
            if not ev_date_str:
                continue

            target_date = datetime.strptime(ev_date_str[:10], "%Y-%m-%d").date()
            diff_days = (target_date - today).days
            title = ev.get("title", "마감 일정")

            should_send = False
            msg_title = ""
            msg_body = ""

            if diff_days == 0 and settings.get("d_day_0", True):
                should_send = True
                msg_title = f"🚨 [D-Day 오늘 마감] {title}"
                msg_body = f"'{title}' 일정이 오늘 마감됩니다!"
            elif diff_days == 1 and settings.get("d_day_1", True):
                should_send = True
                msg_title = f"⏰ [마감 1일 전 (D-1)] {title}"
                msg_body = f"'{title}' 마감 일정이 하루 남았습니다!"
            elif diff_days == 2 and settings.get("d_day_2", True):
                should_send = True
                msg_title = f"⏳ [마감 2일 전 (D-2)] {title}"
                msg_body = f"'{title}' 마감 일정이 2일 남았습니다!"
            elif diff_days == 3 and settings.get("d_day_3", True):
                should_send = True
                msg_title = f"⏳ [마감 3일 전 (D-3)] {title}"
                msg_body = f"'{title}' 마감 일정이 3일 남았습니다!"
            elif diff_days == 5 and settings.get("d_day_5", True):
                should_send = True
                msg_title = f"⏳ [마감 5일 전 (D-5)] {title}"
                msg_body = f"'{title}' 마감 일정이 5일 남았습니다!"
            elif diff_days == 7 and settings.get("d_day_7", True):
                should_send = True
                msg_title = f"⏳ [마감 7일 전 (D-7)] {title}"
                msg_body = f"'{title}' 마감 일정이 7일 남았습니다!"
            elif diff_days == 10 and settings.get("d_day_10", True):
                should_send = True
                msg_title = f"⏳ [마감 10일 전 (D-10)] {title}"
                msg_body = f"'{title}' 마감 일정이 10일 남았습니다!"

            if should_send:
                await send_and_save_notification(
                    user_id="default_user",
                    title=msg_title,
                    body=msg_body,
                    is_daily_summary=False,
                    image_url=ev.get("image_url")
                )
    except Exception as e:
        print(f"❌ [마감 임박 스케줄러 오류]: {e}")


# 작업 2: 💡 당일 스크린샷 정리 브리핑 (일일 분석 리포트)
async def check_daily_summary():
    today_str = get_korean_now().strftime("%Y-%m-%d")
    print(f"⏰ [스케줄러 실행] 당일 스크린샷 정리 브리핑 ({today_str})")

    try:
        # 유저 설정 조회
        settings_res = supabase.table("user_settings").select("*").eq("user_id", "default_user").execute()
        settings = settings_res.data[0] if settings_res.data else {}

        if not settings.get("push_enabled", True) or not settings.get("daily_summary_enabled", True):
            print("ℹ️ [리포트 스킵] 일일 분석 리포트 알림이 꺼져 있습니다.")
            return

        response = (
            supabase.table("analyzed_items")
            .select("id, summary")
            .gte("created_at", f"{today_str}T00:00:00")
            .execute()
        )
        items = response.data or []
        count = len(items)

        if count > 0:
            await send_and_save_notification(
                user_id="default_user",
                title="📊 오늘의 분석 리포트",
                body=f"오늘 하루 동안 총 {count}개의 스크린샷을 분석·정리했습니다. 앱에서 확인해보세요!",
                is_daily_summary=True
            )
    except Exception as e:
        print(f"❌ [일일 브리핑 스케줄러 오류]: {e}")


# 스케줄러 등록 및 가동
def start_scheduler():
    # 1. 매일 오전 09:00 마감 임박 알림 (KST)
    scheduler.add_job(check_deadline_notifications, "cron", hour=9, minute=0, timezone=KST)
    
    # 2. 매일 오후 18:50 일일 요약 리포트 (KST)
    scheduler.add_job(check_daily_summary, "cron", hour=18, minute=50, timezone=KST)
    
    scheduler.start()
    print("🚀 [APScheduler] KST 기준 알림 백그라운드 스케줄러 가동 완료")


# 💡 즉시 수동 테스트용 함수
async def run_manual_test():
    print("🧪 [테스트 실행] 마감 알림 및 일일 리포트 발송 테스트")
    await check_deadline_notifications()
    await check_daily_summary()

if __name__ == "__main__":
    import asyncio
    asyncio.run(run_manual_test())

# import os
# from datetime import datetime, timedelta
# import firebase_admin
# from firebase_admin import credentials, messaging
# from apscheduler.schedulers.asyncio import AsyncIOScheduler
# from supabase import create_client, Client
# from dotenv import load_dotenv

# load_dotenv()

# # Supabase 클라이언트 초기화
# SUPABASE_URL = os.environ.get("SUPABASE_URL")
# SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
# supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# # Firebase Admin SDK 절대 경로 기반 초기화
# BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH", os.path.join(BASE_DIR, "serviceAccountKey.json"))

# if not firebase_admin._apps:
#     if os.path.exists(cred_path):
#         cred = credentials.Certificate(cred_path)
#         firebase_admin.initialize_app(cred)
#         print("✅ [Firebase Admin] 초기화 성공")
#     else:
#         print(f"⚠️ [Firebase Admin] 키 파일을 찾을 수 없습니다: {cred_path}")

# scheduler = AsyncIOScheduler()

# async def send_fcm_notification(fcm_token: str, title: str, body: str):
#     """FCM 단일 기기 푸시 발송 함수"""
#     try:
#         message = messaging.Message(
#             notification=messaging.Notification(title=title, body=body),
#             token=fcm_token,
#         )
#         response = messaging.send(message)
#         print(f"🔔 [FCM 푸시 전송 완료] ID: {response}")
#     except Exception as e:
#         print(f"❌ [FCM 푸시 전송 실패]: {str(e)}")

# # 작업 1: 당일 스크린샷 정리 브리핑 (매일 21:00)
# async def check_daily_captures():
#     today_str = datetime.now().strftime("%Y-%m-%d")
#     print(f"⏰ [스케줄러 실행] 당일 스크린샷 정리 체크 ({today_str})")
    
#     try:
#         response = (
#             supabase.table("analyzed_items")
#             .select("id, summary")
#             .gte("created_at", f"{today_str}T00:00:00")
#             .execute()
#         )
#         items = response.data or []
#         count = len(items)

#         if count > 0:
#             devices = supabase.table("user_devices").select("fcm_token").eq("user_id", "default_user").execute()
#             for dev in devices.data:
#                 await send_fcm_notification(
#                     fcm_token=dev["fcm_token"],
#                     title="📸 오늘의 스크린샷 브리핑",
#                     body=f"오늘 총 {count}개의 스크린샷이 정리되었습니다. 앱에서 확인해보세요!"
#                 )
#     except Exception as e:
#         print(f"❌ [스케줄러 일일 브리핑 에러]: {e}")

# # 작업 2: 캘린더 D-1 마감/일정 알림 (매일 09:00)
# async def check_calendar_d_minus_one():
#     tomorrow_str = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
#     print(f"⏰ [스케줄러 실행] 캘린더 D-1 마감 일정 체크 ({tomorrow_str})")
    
#     try:
#         response = (
#             supabase.table("calendar_events")
#             .select("title")
#             .eq("event_date", tomorrow_str)
#             .execute()
#         )
#         events = response.data or []

#         if events:
#             devices = supabase.table("user_devices").select("fcm_token").eq("user_id", "default_user").execute()
#             for event in events:
#                 event_title = event.get("title", "예정된 일정")
#                 for dev in devices.data:
#                     await send_fcm_notification(
#                         fcm_token=dev["fcm_token"],
#                         title="⏰ [D-1] 내일 마감/예정된 일정 알림",
#                         body=f"내일 일정: '{event_title}'"
#                     )
#     except Exception as e:
#         print(f"❌ [스케줄러 캘린더 D-1 알림 에러]: {e}")

# def start_scheduler():
#     scheduler.add_job(check_daily_captures, "cron", hour=21, minute=0)
#     scheduler.add_job(check_calendar_d_minus_one, "cron", hour=9, minute=0)
#     scheduler.start()
#     print("🚀 [APScheduler] 백그라운드 스케줄러 시작됨")

# # import os
# # from datetime import datetime, timedelta
# # import firebase_admin
# # from firebase_admin import credentials, messaging
# # from apscheduler.schedulers.asyncio import AsyncIOScheduler
# # from supabase import create_client, Client
# # from dotenv import load_dotenv

# # load_dotenv()

# # # Supabase 클라이언트 초기화
# # SUPABASE_URL = os.environ.get("SUPABASE_URL")
# # SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
# # supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# # # Firebase Admin SDK 절대 경로 기반 초기화
# # BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# # cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH", os.path.join(BASE_DIR, "serviceAccountKey.json"))

# # if not firebase_admin._apps:
# #     if os.path.exists(cred_path):
# #         cred = credentials.Certificate(cred_path)
# #         firebase_admin.initialize_app(cred)
# #         print("✅ [Firebase Admin] 초기화 성공")
# #     else:
# #         print(f"⚠️ [Firebase Admin] 키 파일을 찾을 수 없습니다: {cred_path}")

# # scheduler = AsyncIOScheduler()

# # async def send_fcm_notification(fcm_token: str, title: str, body: str):
# #     """FCM 단일 기기 푸시 발송 함수"""
# #     try:
# #         message = messaging.Message(
# #             notification=messaging.Notification(title=title, body=body),
# #             token=fcm_token,
# #         )
# #         response = messaging.send(message)
# #         print(f"🔔 [FCM 푸시 전송 완료] ID: {response}")
# #     except Exception as e:
# #         print(f"❌ [FCM 푸시 전송 실패]: {str(e)}")

# # # 작업 1: 당일 스크린샷 정리 브리핑 (매일 21:00)
# # async def check_daily_captures():
# #     today_str = datetime.now().strftime("%Y-%m-%d")
# #     print(f"⏰ [스케줄러 실행] 당일 스크린샷 정리 체크 ({today_str})")
    
# #     response = (
# #         supabase.table("analyzed_items")
# #         .select("id, summary")
# #         .gte("created_at", f"{today_str}T00:00:00")
# #         .execute()
# #     )
# #     items = response.data or []
# #     count = len(items)

# #     if count > 0:
# #         devices = supabase.table("user_devices").select("fcm_token").eq("user_id", "default_user").execute()
# #         for dev in devices.data:
# #             await send_fcm_notification(
# #                 fcm_token=dev["fcm_token"],
# #                 title="📸 오늘의 스크린샷 브리핑",
# #                 body=f"오늘 총 {count}개의 스크린샷이 정리되었습니다. 앱에서 확인해보세요!"
# #             )

# # # 작업 2: 캘린더 D-1 마감/일정 알림 (매일 09:00)
# # async def check_calendar_d_minus_one():
# #     tomorrow_str = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
# #     print(f"⏰ [스케줄러 실행] 캘린더 D-1 마감 일정 체크 ({tomorrow_str})")
    
# #     response = (
# #         supabase.table("calendar_events")
# #         .select("title")
# #         .eq("event_date", tomorrow_str)
# #         .execute()
# #     )
# #     events = response.data or []

# #     if events:
# #         devices = supabase.table("user_devices").select("fcm_token").eq("user_id", "default_user").execute()
# #         for event in events:
# #             event_title = event.get("title", "예정된 일정")
# #             for dev in devices.data:
# #                 await send_fcm_notification(
# #                     fcm_token=dev["fcm_token"],
# #                     title="⏰ [D-1] 내일 마감/예정된 일정 알림",
# #                     body=f"내일 일정: '{event_title}'"
# #                 )

# # # 테스트용 수동 트리거 함수
# # async def trigger_daily_captures_test():
# #     await check_daily_captures()

# # async def trigger_calendar_d1_test():
# #     await check_calendar_d_minus_one()

# # def start_scheduler():
# #     scheduler.add_job(check_daily_captures, "cron", hour=21, minute=0)
# #     scheduler.add_job(check_calendar_d_minus_one, "cron", hour=9, minute=0)
# #     scheduler.start()
# #     print("🚀 [APScheduler] 백그라운드 스케줄러 시작됨")


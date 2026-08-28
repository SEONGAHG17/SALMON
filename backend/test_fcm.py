import firebase_admin
from firebase_admin import credentials, messaging

if not firebase_admin._apps:
    cred = credentials.Certificate("service_account.json")
    firebase_admin.initialize_app(cred)

# 실제 에뮬레이터 토큰 입력
TARGET_TOKEN = "방금_확인한_실제_에뮬레이터_FCM_토큰"

def send_daily_summary_test():
    """1. 일일 분석 요약 알림 테스트 (salmonImage.png 표출)"""
    message = messaging.Message(
        notification=messaging.Notification(
            title="오늘의 분석 리포트",
            body="오늘 하루 동안 12개의 이미지를 분석했습니다!",
        ),
        data={
            "type": "daily_summary",
            "count": "12",
        },
        token=TARGET_TOKEN,
    )
    res = messaging.send(message)
    print(f"✅ 일일 요약 알림 발송 성공: {res}")

def send_dday_test():
    """2. D-Day 일정 사진 알림 테스트 (일정 이미지 표출)"""
    message = messaging.Message(
        notification=messaging.Notification(
            title="[공모전 접수] 마감 D-3",
            body="등록하신 일정이 3일 남았습니다. 준비 상황을 확인해보세요!",
        ),
        data={
            "type": "dday",
            "image_url": "https://picsum.photos/200", # 테스트용 이미지 URL
        },
        token=TARGET_TOKEN,
    )
    res = messaging.send(message)
    print(f"✅ D-Day 알림 발송 성공: {res}")

if __name__ == "__main__":
    # 원하는 테스트 함수를 호출해 보세요
    send_daily_summary_test()
    # send_dday_test()
# SALMON

SALMON/
├── backend/                           # FastAPI 백엔드
│   ├── main.py                        # FastAPI 메인 엔트리포인트, Watsonx/Qdrant/파이프라인
│   ├── crud.py                        # Supabase DB 연동 CRUD 및 카테고리 색상/삭제 관리
│   ├── setting.py                     # 카테고리 설정, 푸시 알림 설정 및 히스토리 API
│   ├── history.py                     # 분석된 히스토리 목록 조회/관리 API
│   ├── calender.py                    # 캘린더 일정 CRUD API
│   ├── map.py                         # 지도 장소 매핑 API
│   ├── chatbot.py                     # 대화형 세션 및 챗봇 API
│   └── basetime.py                    # KST 기준 스케줄러 관리 (APScheduler)
│
├── frontend/                          # Flutter 모바일 앱
│   ├── lib/
│   │   ├── main.dart                  # 앱 시작점 (Firebase 초기화, Theme, MainNavigationScreen)
│   │   ├── constants/
│   │   │   └── constants.dart         # 백엔드 Base URL (10.0.2.2:8000 등)
│   │   ├── styles/
│   │   │   └── app_theme.dart         # 브랜드 색상 (AppColors.brand) 및 테마 설정
│   │   ├── services/
│   │   │   ├── fcm.dart               # Firebase Cloud Messaging 토큰 및 리스너
│   │   │   └── notification_service.dart # 로컬 푸시 알림 엔진
│   │   └── screens/
│   │       ├── nevigate.dart          # 하단 네비게이션 바 (MainNavigationScreen)
│   │       ├── home.dart              # 메인 대시보드 화면
│   │       ├── upload.dart            # 이미지 업로드 및 OCR 분석 요청 화면
│   │       ├── chatbot.dart           # RAG 기반 AI 비서 챗봇 화면
│   │       ├── calender.dart          # 추출된 일정 확인 캘린더 화면
│   │       ├── category.dart          # 카테고리별 보관함 목록 화면
│   │       ├── history.dart           # 전체 캡처 분석 내역 화면
│   │       ├── setting.dart           # 알림 설정 및 마이페이지 화면
│   │       └── settingcategory.dart   # 카테고리 색상/추가/삭제 관리 화면
│   │
│   └── pubspec.yaml                   # Flutter 의존성 설정

# SALMON
SALMON/
├── backend/                           # FastAPI 백엔드 서버
│   ├── main.py                        # 엔트리포인트 & watsonx/Qdrant 분석 파이프라인
│   ├── crud.py                        # Supabase DB CRUD 및 카테고리 관리 로직
│   ├── setting.py                     # 카테고리/푸시 설정 및 알림 내역 API
│   ├── history.py                     # 캡처 분석 히스토리 조회/관리 API
│   ├── calender.py                    # 캘린더 일정 관리 API
│   ├── map.py                         # 지도 장소 매핑 API
│   ├── chatbot.py                     # Qdrant RAG 기반 세션형 챗봇 API
│   └── basetime.py                    # 한국 표준시(KST) 기반 알림 스케줄러
│
├── frontend/                          # Flutter 모바일 애플리케이션
│   ├── lib/
│   │   ├── main.dart                  # 앱 진입점 및 테마/초기화 설정
│   │   ├── constants/                 # 백엔드 Base URL 및 공통 상수 정의
│   │   ├── styles/                    # 브랜드 컬러(Coral) 및 UI 테마
│   │   ├── services/                  # FCM 및 로컬 푸시 알림 엔진
│   │   └── screens/
│   │       ├── nevigate.dart          # 6대 메인 탭 네비게이션 컨트롤러
│   │       ├── home.dart              # 대시보드 화면 (요약 & 최근 항목)
│   │       ├── upload.dart            # 이미지 업로드 및 실시간 AI 분석
│   │       ├── chatbot.dart           # RAG 대화형 AI 비서
│   │       ├── calender.dart          # 일정 관리 캘린더 뷰
│   │       ├── category.dart          # 카테고리별 아카이브 뷰
│   │       ├── history.dart           # 전체 캡처 분석 타임라인
│   │       ├── setting.dart           # 푸시 알림/계정 환경설정
│   │       └── settingcategory.dart   # 카테고리 추가/색상 커스텀/삭제
│   └── pubspec.yaml
└── README.md

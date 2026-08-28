# SALMON

# 🐟 SALMON (Screenshot Action-Linker for Maps & Organized Notes)

> **스마트폰 스크린샷 한 장으로 완성되는 지능형 개인 정보 비서**  
> OCR 및 멀티모달 AI 비전 기술을 통해 스크린샷 속 텍스트, 일정, 장소, 링크를 자동 추출하고 체계적으로 관리합니다.

---

## 📌 프로젝트 소개 (Overview)

현대인은 중요한 정보(공모전, 장학금 공고, 항공권, 맛집, 모바일 쿠폰 등)를 간편하게 캡처하지만, 갤러리에 쌓인 이미지를 다시 찾거나 캘린더/지도에 직접 옮겨 적는 데 많은 번거로움을 겪습니다.

**SALMON**은 스크린샷 이미지를 업로드하는 즉시:
1. **AI 멀티모달 분석**: 텍스트(OCR) 인식 및 핵심 정보(상호명, 마감일, 주소, URL) 추출
2. **자동 분류 & 매핑**: 카테고리 자동 분류 및 캘린더 일정/지도 장소 자동 등록
3. **지능형 RAG 챗봇**: 저장된 스크린샷 내용을 자연어로 질의응답
4. **개인화 푸시 알림**: D-Day 및 일일 요약 알림 제공

---

## 🛠 기술 스택 (Tech Stack)

### Frontend
- **Framework**: Flutter (Dart)
- **UI/Theme**: Material 3 Design
- **Push Notification**: Firebase Cloud Messaging (FCM), Flutter Local Notifications

### Backend & AI
- **Framework**: FastAPI (Python 3.10+)
- **AI Vision / LLM**: IBM watsonx.ai (`meta-llama/llama-4-maverick-17b-128e-instruct-fp8`)
- **Embedding Model**: IBM watsonx.ai (`intfloat/multilingual-e5-large`)
- **Vector DB**: Qdrant Cloud (스크린샷 기반 RAG 시맨틱 검색)
- **Database & Storage**: Supabase (PostgreSQL, Storage)
- **Task Scheduler**: APScheduler (KST 기준 D-Day/일일 브리핑 푸시)

---

## 📂 프로젝트 구조 (Project Structure)

```text
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

import os
import asyncio
from dotenv import load_dotenv
from qdrant_client import QdrantClient
from ibm_watsonx_ai import Credentials
from ibm_watsonx_ai.foundation_models import Embeddings, ModelInference
from ibm_watsonx_ai.metanames import GenChatParamsMetaNames as ChatParams

load_dotenv()

# 1. 설정값 로드
QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")
watsonx_api_key = os.environ.get("WATSONX_API_KEY")
watsonx_url = os.environ.get("WATSONX_URL", "https://us-south.ml.cloud.ibm.com")
watsonx_project_id = os.environ.get("WATSONX_PROJECT_ID")
embedding_model_id = os.environ.get("WATSONX_EMBEDDING_MODEL_ID", "intfloat/multilingual-e5-large")
watsonx_chat_model_id = os.environ.get("WATSONX_CHAT_MODEL_ID", "ibm/granite-4-h-small")

test_question = "공모전이나 등록된 일정 요약해줘"

async def test_full_pipeline():
    print(f"\n🚀 [1단계] Watsonx 임베딩 테스트: '{test_question}' 벡터화 진행 중...")
    creds = Credentials(url=watsonx_url, api_key=watsonx_api_key)
    embed_engine = Embeddings(
        model_id=embedding_model_id,
        credentials=creds,
        project_id=watsonx_project_id
    )
    query_vector = embed_engine.embed_documents([test_question])[0]
    print(f"   -> 임베딩 성공! (차원 수: {len(query_vector)})")

    print(f"\n🔍 [2단계] Qdrant 벡터 유사도 검색 실행 중...")
    qdrant = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)
    
    # 최신 qdrant-client query_points 사용 (search fallback 포함)
    try:
        query_res = qdrant.query_points(
            collection_name="screenshots",
            query=query_vector,
            limit=3
        )
        hits = query_res.points
    except AttributeError:
        hits = qdrant.search(
            collection_name="screenshots",
            query_vector=query_vector,
            limit=3
        )
    
    if not hits:
        print("   ❌ Qdrant에서 검색된 데이터가 없습니다.")
        return

    print(f"   -> 검색 성공! 총 {len(hits)}개의 연관 스크린샷 추출:")
    context_lines = []
    for i, hit in enumerate(hits):
        payload = hit.payload or {}
        summary = payload.get("summary", "")
        category = payload.get("category", "")
        score = round(hit.score, 4)
        print(f"      [{i+1}] (유사도: {score}) [{category}] {summary}")
        context_lines.append(f"[{i+1}] [{category}] {summary}")

    context_text = "\n".join(context_lines)

    print(f"\n🧠 [3단계] Qdrant 검색 결과를 Watsonx Granite 모델에 주입하여 답변 생성 중...")
    chat_model = ModelInference(
        model_id=watsonx_chat_model_id,
        credentials=creds,
        project_id=watsonx_project_id
    )
    messages = [
        {"role": "system", "content": f"너는 AI 비서이다. 다음 검색된 스크린샷 정보를 바탕으로 답변하라.\n\n[검색 데이터]:\n{context_text}"},
        {"role": "user", "content": test_question}
    ]
    response = chat_model.chat(
        messages=messages,
        params={ChatParams.TEMPERATURE: 0.2, ChatParams.MAX_TOKENS: 400}
    )
    
    try:
        reply = response["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, TypeError):
        reply = response["results"][0]["generated_text"].strip()

    print("\n" + "="*50)
    print("🤖 [Watsonx Granite 최종 생성 답변]")
    print("="*50)
    print(reply)
    print("="*50)
    print("✅ [검증 완료] Watsonx 임베딩 -> Qdrant 벡터 검색 -> Watsonx Granite 연동 정상 작동 확인!")

if __name__ == "__main__":
    asyncio.run(test_full_pipeline())
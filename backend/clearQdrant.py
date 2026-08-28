# clear_qdrant.py
import os
from qdrant_client import QdrantClient
from dotenv import load_dotenv

load_dotenv()

QDRANT_URL = os.environ.get("QDRANT_URL")
QDRANT_API_KEY = os.environ.get("QDRANT_API_KEY")

if QDRANT_URL:
    client = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)
    try:
        client.delete_collection(collection_name="screenshots")
        print("✅ Qdrant 'screenshots' 컬렉션 삭제 완료")
        
        # 새 컬렉션 재생성 (1024차원 multilingual-e5-large 기준)
        from qdrant_client.http import models
        client.create_collection(
            collection_name="screenshots",
            vectors_config=models.VectorParams(size=1024, distance=models.Distance.COSINE)
        )
        print("✅ Qdrant 'screenshots' 컬렉션 새로 생성 완료")
    except Exception as e:
        print(f"⚠️ Qdrant 초기화 오류: {e}")
"""
FYNA AI Microservice — Entry point.

FastAPI application that provides AI-powered financial analysis:
- Transaction classification (NLP)
- Spending pattern detection (statistical)
- Spending prediction (time series)
- Investment recommendations (rule-based)

Run: uvicorn app.main:app --host 0.0.0.0 --port 8081
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings

logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info(f"Starting {settings.service_name} v{settings.model_version}")

    # Pre-carrega o modelo de embeddings antes de aceitar requests.
    # Evita latência elevada no primeiro classify (pode levar vários segundos).
    try:
        import asyncio
        from concurrent.futures import ThreadPoolExecutor

        def _load_model():
            from app.services.classifier import _get_embedding_model
            model = _get_embedding_model()
            return model is not None

        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor(max_workers=1) as pool:
            loaded = await loop.run_in_executor(pool, _load_model)

        if loaded:
            logger.info("Embedding model pre-loaded successfully")
        else:
            logger.warning("Using TF-IDF fallback (transformer unavailable)")
    except Exception as e:
        logger.warning(f"Model pre-load failed — first request may be slow: {e}")

    yield
    logger.info("Shutting down")


app = FastAPI(
    title="Fyna AI Engine",
    description="AI microservice for Fyna financial management app",
    version=settings.model_version,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.routes import router
app.include_router(router)

"""
API Routes — Endpoints chamados pelo backend Spring Boot.

Todos os endpoints protegidos exigem a header X-Internal-Key,
cujo valor deve corresponder a FYNA_AI_INTERNAL_API_KEY no ambiente.
O endpoint /health é público para health checks de infraestrutura.
"""

import logging
from datetime import date

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.schemas.schemas import (
    AnalysisResponse,
    AnalyzeUserRequest,
    ClassificationResult,
    ClassifyTransactionRequest,
    GenerateRecommendationsRequest,
    HealthResponse,
    PredictSpendingRequest,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/v1/ai-engine", tags=["AI Engine"])


def verify_internal_key(x_internal_key: str = Header(..., alias="X-Internal-Key")) -> None:
    """Dependency que valida a API key interna enviada pelo Spring Boot."""
    if x_internal_key != settings.internal_api_key:
        logger.warning("Tentativa de acesso com API key inválida")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="API key inválida ou ausente",
        )


# Atalho reutilizável para injetar a dependência de auth em todos os endpoints protegidos
_auth = Depends(verify_internal_key)


@router.get("/health", response_model=HealthResponse)
def health_check():
    """Health check público — sem autenticação."""
    from app.services.classifier import is_model_loaded
    return HealthResponse(
        status="ok",
        model_version=settings.model_version,
        classifier_loaded=is_model_loaded(),
    )


@router.post("/classify", response_model=ClassificationResult, dependencies=[_auth])
def classify_transaction(
    request: ClassifyTransactionRequest,
    db: Session = Depends(get_db),
):
    try:
        from app.services.classifier import classify_transaction as do_classify
        return do_classify(
            db=db,
            transaction_id=request.transaction_id,
            user_id=request.user_id,
            description=request.description,
            amount=float(request.amount),
            transaction_type=request.transaction_type,
        )
    except Exception as e:
        logger.error(f"Classification failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze", response_model=AnalysisResponse, dependencies=[_auth])
def analyze_user(
    request: AnalyzeUserRequest,
    db: Session = Depends(get_db),
):
    user_id = request.user_id
    patterns_count = 0
    predictions_count = 0
    recommendations_count = 0
    pending = 0

    try:
        from app.services.pattern_detector import detect_patterns
        patterns = detect_patterns(db, user_id)
        patterns_count = len(patterns)
    except Exception as e:
        logger.error(f"Pattern detection failed: {e}", exc_info=True)

    try:
        from app.services.spending_predictor import predict_spending
        today = date.today()
        next_month = date(today.year + 1, 1, 1) if today.month == 12 else date(today.year, today.month + 1, 1)
        predictions = predict_spending(db, user_id, next_month)
        predictions_count = len(predictions)
    except Exception as e:
        logger.error(f"Prediction failed: {e}", exc_info=True)

    try:
        from app.services.investment_advisor import generate_recommendations
        recommendations = generate_recommendations(db, user_id)
        recommendations_count = len(recommendations)
    except Exception as e:
        logger.error(f"Recommendations failed: {e}", exc_info=True)

    try:
        from app.models.models import AIClassification, Transaction
        from sqlalchemy import and_
        pending = (
            db.query(AIClassification)
            .join(Transaction, AIClassification.transaction_id == Transaction.id)
            .filter(and_(
                Transaction.user_id == user_id,
                AIClassification.was_confirmed == False,
                AIClassification.was_corrected == False,
            ))
            .count()
        )
    except Exception:
        pass

    return AnalysisResponse(
        user_id=user_id,
        patterns_detected=patterns_count,
        predictions_generated=predictions_count,
        recommendations_generated=recommendations_count,
        classifications_pending=pending,
        model_version=settings.model_version,
    )


@router.post("/predict", dependencies=[_auth])
def predict_spending_endpoint(
    request: PredictSpendingRequest,
    db: Session = Depends(get_db),
):
    try:
        from app.services.spending_predictor import predict_spending
        return predict_spending(db, request.user_id, request.target_month)
    except Exception as e:
        logger.error(f"Prediction failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/recommend", dependencies=[_auth])
def generate_recommendations_endpoint(
    request: GenerateRecommendationsRequest,
    db: Session = Depends(get_db),
):
    try:
        from app.services.investment_advisor import generate_recommendations
        return generate_recommendations(db, request.user_id)
    except Exception as e:
        logger.error(f"Recommendations failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(e))

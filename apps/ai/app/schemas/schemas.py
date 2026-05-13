"""Pydantic schemas — request/response DTOs for the AI engine API."""

from datetime import date, datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


# ═══ Requests (from Spring Boot) ═══

class ClassifyTransactionRequest(BaseModel):
    transaction_id: UUID
    user_id: UUID
    description: str
    amount: Decimal
    transaction_type: str  # INCOME, EXPENSE, TRANSFER


class AnalyzeUserRequest(BaseModel):
    """Triggers full analysis: patterns + predictions + recommendations."""
    user_id: UUID


class PredictSpendingRequest(BaseModel):
    user_id: UUID
    target_month: date  # first day of the month to predict


class GenerateRecommendationsRequest(BaseModel):
    user_id: UUID


# ═══ Responses (to Spring Boot) ═══

class ClassificationResult(BaseModel):
    transaction_id: UUID
    suggested_category_id: Optional[UUID] = None
    suggested_category_name: Optional[str] = None
    confidence_score: float
    model_version: str


class PatternResult(BaseModel):
    pattern_type: str
    description: str
    pattern_data: dict
    significance_score: float
    detected_from: date
    detected_to: date


class PredictionResult(BaseModel):
    category_id: Optional[UUID] = None
    category_name: Optional[str] = None
    prediction_date: date
    predicted_amount: float
    confidence_lower: float
    confidence_upper: float


class RecommendationResult(BaseModel):
    recommendation_type: str
    title: str
    description: str
    allocation_suggestion: Optional[dict] = None
    potential_return: Optional[float] = None
    risk_level: Optional[float] = None


# ═══ Aggregated responses ═══

class AnalysisResponse(BaseModel):
    user_id: UUID
    patterns_detected: int = 0
    predictions_generated: int = 0
    recommendations_generated: int = 0
    classifications_pending: int = 0
    model_version: str


class HealthResponse(BaseModel):
    status: str = "ok"
    model_version: str
    classifier_loaded: bool = False

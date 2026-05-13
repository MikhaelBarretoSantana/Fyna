"""
SQLAlchemy models — maps the existing Fyna PostgreSQL schema.
Read-only for transactions/categories/accounts, read-write for AI tables.
"""

import uuid
from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean, Column, Date, DateTime, ForeignKey, Integer,
    Numeric, String, Text, func,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.database import Base


# ─── Read-only models (populated by Spring Boot) ───

class User(Base):
    __tablename__ = "users"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    login = Column(String(50), nullable=False)
    email = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    status = Column(String(20), nullable=False, default="ACTIVE")


class Account(Base):
    __tablename__ = "accounts"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    type = Column(String(30), nullable=False)
    current_balance = Column(Numeric(15, 2), nullable=False, default=0)
    is_active = Column(Boolean, nullable=False, default=True)


class Category(Base):
    __tablename__ = "categories"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=True)
    parent_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True)
    name = Column(String(100), nullable=False)
    icon = Column(String(50))
    color = Column(String(7))
    type = Column(String(20), nullable=False)
    is_system = Column(Boolean, nullable=False, default=False)
    is_active = Column(Boolean, nullable=False, default=True)
    display_order = Column(Integer, nullable=False, default=0)


class Transaction(Base):
    __tablename__ = "transactions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    account_id = Column(UUID(as_uuid=True), ForeignKey("accounts.id"), nullable=False)
    category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True)
    type = Column(String(20), nullable=False)
    amount = Column(Numeric(15, 2), nullable=False)
    description = Column(String(255), nullable=False)
    notes = Column(Text)
    transaction_date = Column(Date, nullable=False)
    is_paid = Column(Boolean, nullable=False, default=True)
    is_recurring = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    category = relationship("Category", foreign_keys=[category_id])


class RecurringTransaction(Base):
    __tablename__ = "recurring_transactions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    account_id = Column(UUID(as_uuid=True), ForeignKey("accounts.id"), nullable=False)
    category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True)
    type = Column(String(20), nullable=False)
    amount = Column(Numeric(15, 2), nullable=False)
    description = Column(String(255), nullable=False)
    frequency = Column(String(20), nullable=False)
    next_occurrence = Column(Date, nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)


class Budget(Base):
    __tablename__ = "budgets"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True)
    name = Column(String(100), nullable=False)
    amount_limit = Column(Numeric(15, 2), nullable=False)
    amount_spent = Column(Numeric(15, 2), nullable=False, default=0)
    period_type = Column(String(20), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)


class FinancialGoal(Base):
    __tablename__ = "financial_goals"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(100), nullable=False)
    target_amount = Column(Numeric(15, 2), nullable=False)
    current_amount = Column(Numeric(15, 2), nullable=False, default=0)
    target_date = Column(Date)
    status = Column(String(20), nullable=False, default="IN_PROGRESS")
    priority = Column(String(10), nullable=False, default="MEDIUM")


class RiskProfile(Base):
    __tablename__ = "risk_profiles"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, unique=True)
    risk_tolerance = Column(String(20), nullable=False)
    investment_horizon_years = Column(Integer, nullable=False)
    monthly_income = Column(Numeric(15, 2))
    monthly_expenses = Column(Numeric(15, 2))
    emergency_fund = Column(Numeric(15, 2))
    total_investments = Column(Numeric(15, 2))
    questionnaire_answers = Column(JSONB)
    calculated_score = Column(Numeric(5, 2), nullable=False)


# ─── Read-write models (populated by THIS microservice) ───

class AIClassification(Base):
    __tablename__ = "ai_classifications"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    transaction_id = Column(UUID(as_uuid=True), ForeignKey("transactions.id"), nullable=False)
    suggested_category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True)
    confirmed_category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True)
    confidence_score = Column(Numeric(5, 4), nullable=False)
    original_text = Column(String(500), nullable=False)
    model_version = Column(String(50), nullable=False)
    was_confirmed = Column(Boolean, nullable=False, default=False)
    was_corrected = Column(Boolean, nullable=False, default=False)
    feature_vector = Column(JSONB)
    classified_at = Column(DateTime(timezone=True), server_default=func.now())
    confirmed_at = Column(DateTime(timezone=True))

    transaction = relationship("Transaction", foreign_keys=[transaction_id])
    suggested_category = relationship("Category", foreign_keys=[suggested_category_id])


class SpendingPrediction(Base):
    __tablename__ = "spending_predictions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id"), nullable=True)
    prediction_date = Column(Date, nullable=False)
    predicted_amount = Column(Numeric(15, 2), nullable=False)
    actual_amount = Column(Numeric(15, 2))
    confidence_lower = Column(Numeric(15, 2), nullable=False)
    confidence_upper = Column(Numeric(15, 2), nullable=False)
    model_version = Column(String(50), nullable=False)
    model_parameters = Column(JSONB)
    generated_at = Column(DateTime(timezone=True), server_default=func.now())

    category = relationship("Category", foreign_keys=[category_id])


class SpendingPattern(Base):
    __tablename__ = "spending_patterns"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    pattern_type = Column(String(30), nullable=False)
    description = Column(Text, nullable=False)
    pattern_data = Column(JSONB, nullable=False)
    significance_score = Column(Numeric(5, 4), nullable=False)
    detected_from = Column(Date, nullable=False)
    detected_to = Column(Date, nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)
    model_version = Column(String(50), nullable=False)
    detected_at = Column(DateTime(timezone=True), server_default=func.now())


class InvestmentRecommendation(Base):
    __tablename__ = "investment_recommendations"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    risk_profile_id = Column(UUID(as_uuid=True), ForeignKey("risk_profiles.id"), nullable=True)
    recommendation_type = Column(String(30), nullable=False)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    allocation_suggestion = Column(JSONB)
    potential_return = Column(Numeric(5, 2))
    risk_level = Column(Numeric(5, 2))
    was_viewed = Column(Boolean, nullable=False, default=False)
    was_followed = Column(Boolean)
    model_version = Column(String(50), nullable=False)
    generated_at = Column(DateTime(timezone=True), server_default=func.now())
    viewed_at = Column(DateTime(timezone=True))

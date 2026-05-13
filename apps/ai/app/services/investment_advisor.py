"""
Investment Advisor — Generates recommendations based on risk profile,
spending patterns, and financial goals.

Rule-based engine with portfolio allocation models per risk tolerance.
"""

import uuid
import json
import logging
from collections import defaultdict
from datetime import date, timedelta
from decimal import Decimal

import numpy as np
from sqlalchemy import and_
from sqlalchemy.orm import Session

from app.config import settings
from app.models.models import (
    InvestmentRecommendation, RiskProfile, Transaction,
    Account, FinancialGoal, Budget,
)
from app.schemas.schemas import RecommendationResult

logger = logging.getLogger(__name__)

# ─── Allocation templates by risk tolerance ───
ALLOCATIONS = {
    "CONSERVATIVE": {
        "Renda Fixa": 60, "Tesouro Direto": 20, "Fundos Imobiliários": 10, "Ações": 5, "Reserva": 5,
    },
    "MODERATELY_CONSERVATIVE": {
        "Renda Fixa": 45, "Tesouro Direto": 20, "Fundos Imobiliários": 15, "Ações": 10, "Internacional": 5, "Reserva": 5,
    },
    "MODERATE": {
        "Renda Fixa": 30, "Tesouro Direto": 15, "Fundos Imobiliários": 20, "Ações": 20, "Internacional": 10, "Reserva": 5,
    },
    "MODERATELY_AGGRESSIVE": {
        "Renda Fixa": 15, "Tesouro Direto": 10, "Fundos Imobiliários": 20, "Ações": 30, "Internacional": 15, "Cripto": 5, "Reserva": 5,
    },
    "AGGRESSIVE": {
        "Renda Fixa": 10, "Fundos Imobiliários": 15, "Ações": 35, "Internacional": 20, "Cripto": 10, "Startups": 5, "Reserva": 5,
    },
}

RETURN_ESTIMATES = {
    "CONSERVATIVE": 8.5,
    "MODERATELY_CONSERVATIVE": 10.0,
    "MODERATE": 12.5,
    "MODERATELY_AGGRESSIVE": 15.0,
    "AGGRESSIVE": 18.0,
}


def generate_recommendations(
    db: Session, user_id: uuid.UUID
) -> list[RecommendationResult]:
    """Generate investment recommendations for a user."""
    # 1. Get risk profile
    risk_profile = (
        db.query(RiskProfile)
        .filter(RiskProfile.user_id == user_id)
        .first()
    )

    if not risk_profile:
        logger.info(f"User {user_id}: no risk profile, generating basic recommendation")
        return [_basic_recommendation()]

    # 2. Get financial context
    end = date.today()
    start = end - timedelta(days=90)

    income_txs = (
        db.query(Transaction)
        .filter(and_(
            Transaction.user_id == user_id,
            Transaction.type == "INCOME",
            Transaction.is_paid == True,
            Transaction.transaction_date.between(start, end),
        ))
        .all()
    )
    expense_txs = (
        db.query(Transaction)
        .filter(and_(
            Transaction.user_id == user_id,
            Transaction.type == "EXPENSE",
            Transaction.is_paid == True,
            Transaction.transaction_date.between(start, end),
        ))
        .all()
    )

    total_income = sum(float(tx.amount) for tx in income_txs)
    total_expense = sum(float(tx.amount) for tx in expense_txs)
    monthly_surplus = (total_income - total_expense) / 3  # 3-month average

    goals = (
        db.query(FinancialGoal)
        .filter(and_(
            FinancialGoal.user_id == user_id,
            FinancialGoal.status == "IN_PROGRESS",
        ))
        .all()
    )

    accounts = (
        db.query(Account)
        .filter(and_(Account.user_id == user_id, Account.is_active == True))
        .all()
    )
    total_balance = sum(float(a.current_balance) for a in accounts)

    results = []

    # 3. Asset allocation recommendation
    tolerance = risk_profile.risk_tolerance
    allocation = ALLOCATIONS.get(tolerance, ALLOCATIONS["MODERATE"])
    est_return = RETURN_ESTIMATES.get(tolerance, 12.5)
    risk_score = float(risk_profile.calculated_score)

    results.append(RecommendationResult(
        recommendation_type="ASSET_ALLOCATION",
        title=f"Alocação {_tolerance_label(tolerance)}",
        description=(
            f"Com base no seu perfil {_tolerance_label(tolerance).lower()} "
            f"(score {risk_score:.0f}/100), sugerimos a seguinte distribuição "
            f"de investimentos para maximizar retorno com seu nível de conforto."
        ),
        allocation_suggestion=allocation,
        potential_return=est_return,
        risk_level=risk_score,
    ))

    # 4. Emergency fund check
    emergency_fund = float(risk_profile.emergency_fund or 0)
    monthly_expense_avg = total_expense / 3 if total_expense > 0 else 0
    emergency_months = emergency_fund / monthly_expense_avg if monthly_expense_avg > 0 else 0

    if emergency_months < 6:
        needed = (6 * monthly_expense_avg) - emergency_fund
        results.append(RecommendationResult(
            recommendation_type="RISK_ADJUSTMENT",
            title="Reserva de emergência insuficiente",
            description=(
                f"Sua reserva cobre apenas {emergency_months:.1f} meses de despesas. "
                f"O ideal são 6 meses. Sugerimos priorizar R$ {needed:.0f} em renda fixa "
                f"de alta liquidez (Tesouro Selic ou CDB com liquidez diária) antes de "
                f"diversificar em outros ativos."
            ),
            potential_return=None,
            risk_level=20.0,
        ))

    # 5. Surplus-based recommendation
    if monthly_surplus > 100:
        results.append(RecommendationResult(
            recommendation_type="NEW_INVESTMENT",
            title=f"Invista R$ {monthly_surplus:.0f}/mês",
            description=(
                f"Nos últimos 3 meses, sua média de sobra mensal foi R$ {monthly_surplus:.0f}. "
                f"Investindo esse valor mensalmente com retorno estimado de {est_return:.1f}% a.a., "
                f"em 5 anos você teria aproximadamente R$ {_future_value(monthly_surplus, est_return, 5):.0f}."
            ),
            allocation_suggestion=allocation,
            potential_return=est_return,
            risk_level=risk_score,
        ))
    elif monthly_surplus < 0:
        results.append(RecommendationResult(
            recommendation_type="RISK_ADJUSTMENT",
            title="Gastos acima da receita",
            description=(
                f"Nos últimos 3 meses, seus gastos superaram a receita em "
                f"R$ {abs(monthly_surplus):.0f}/mês. Antes de investir, "
                f"recomendamos equilibrar o orçamento e eliminar dívidas."
            ),
            potential_return=None,
            risk_level=90.0,
        ))

    # 6. Goal-based suggestions
    for goal in goals[:2]:
        remaining = float(goal.target_amount) - float(goal.current_amount)
        if remaining <= 0:
            continue
        if goal.target_date and monthly_surplus > 0:
            months_left = max(
                (goal.target_date.year - date.today().year) * 12 +
                (goal.target_date.month - date.today().month), 1
            )
            monthly_needed = remaining / months_left
            results.append(RecommendationResult(
                recommendation_type="NEW_INVESTMENT",
                title=f"Meta: {goal.name}",
                description=(
                    f"Para atingir R$ {float(goal.target_amount):.0f} até "
                    f"{goal.target_date.strftime('%m/%Y')}, você precisa poupar "
                    f"R$ {monthly_needed:.0f}/mês. Faltam R$ {remaining:.0f}."
                ),
                potential_return=None,
                risk_level=None,
            ))

    # Delete old recommendations and persist new ones
    db.query(InvestmentRecommendation).filter(
        and_(
            InvestmentRecommendation.user_id == user_id,
            InvestmentRecommendation.was_viewed == False,
        )
    ).delete()
    db.flush()

    for r in results:
        rec = InvestmentRecommendation(
            id=uuid.uuid4(),
            user_id=user_id,
            risk_profile_id=risk_profile.id,
            recommendation_type=r.recommendation_type,
            title=r.title,
            description=r.description,
            allocation_suggestion=r.allocation_suggestion,
            potential_return=r.potential_return,
            risk_level=r.risk_level,
            model_version=settings.model_version,
        )
        db.add(rec)

    db.commit()
    logger.info(f"User {user_id}: generated {len(results)} recommendations")
    return results


def _basic_recommendation() -> RecommendationResult:
    return RecommendationResult(
        recommendation_type="RISK_ADJUSTMENT",
        title="Complete seu perfil de investidor",
        description=(
            "Para receber recomendações personalizadas, complete o questionário "
            "de perfil de risco. Isso nos permite sugerir a alocação ideal "
            "de acordo com seus objetivos e tolerância a risco."
        ),
        potential_return=None,
        risk_level=None,
    )


def _tolerance_label(tolerance: str) -> str:
    labels = {
        "CONSERVATIVE": "Conservador",
        "MODERATELY_CONSERVATIVE": "Moderadamente Conservador",
        "MODERATE": "Moderado",
        "MODERATELY_AGGRESSIVE": "Moderadamente Agressivo",
        "AGGRESSIVE": "Agressivo",
    }
    return labels.get(tolerance, tolerance)


def _future_value(monthly: float, annual_rate: float, years: int) -> float:
    """Future value of monthly investments with compound interest."""
    r = annual_rate / 100 / 12
    n = years * 12
    if r == 0:
        return monthly * n
    return monthly * (((1 + r) ** n - 1) / r)

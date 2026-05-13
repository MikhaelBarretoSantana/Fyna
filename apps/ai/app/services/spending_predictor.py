"""
Spending Predictor — Forecasts next month's spending per category.

Uses exponential smoothing (Holt-Winters) with confidence intervals.
Falls back to simple moving average when data is insufficient.
"""

import uuid
import logging
from collections import defaultdict
from datetime import date, timedelta
from decimal import Decimal

import numpy as np
from sqlalchemy import and_
from sqlalchemy.orm import Session

from app.config import settings
from app.models.models import SpendingPrediction, Transaction, Category
from app.schemas.schemas import PredictionResult

logger = logging.getLogger(__name__)


def predict_spending(
    db: Session, user_id: uuid.UUID, target_month: date
) -> list[PredictionResult]:
    """Predict spending for target_month, broken down by category."""
    # Get N months of history
    n_months = settings.prediction_months_history
    history_start = _subtract_months(target_month, n_months)

    txs = (
        db.query(Transaction)
        .filter(
            and_(
                Transaction.user_id == user_id,
                Transaction.type == "EXPENSE",
                Transaction.is_paid == True,
                Transaction.transaction_date.between(history_start, target_month - timedelta(days=1)),
            )
        )
        .all()
    )

    if len(txs) < 5:
        logger.info(f"User {user_id}: only {len(txs)} expense txs, skipping prediction")
        return []

    # Group by (category_id, month)
    cat_monthly: dict[str, dict[date, float]] = defaultdict(lambda: defaultdict(float))
    cat_names: dict[str, str] = {}
    total_monthly: dict[date, float] = defaultdict(float)

    for tx in txs:
        cid = str(tx.category_id) if tx.category_id else "_total"
        month_key = tx.transaction_date.replace(day=1)
        amount = float(tx.amount)
        cat_monthly[cid][month_key] += amount
        total_monthly[month_key] += amount
        if tx.category_id and tx.category:
            cat_names[cid] = tx.category.name

    results = []

    # Predict per category
    for cid, monthly in cat_monthly.items():
        if cid == "_total":
            continue
        pred = _forecast_series(monthly, target_month, n_months)
        if pred is None:
            continue

        cat_name = cat_names.get(cid)
        cat_uuid = uuid.UUID(cid) if cid != "_total" else None

        result = PredictionResult(
            category_id=cat_uuid,
            category_name=cat_name,
            prediction_date=target_month,
            predicted_amount=round(pred["predicted"], 2),
            confidence_lower=round(pred["lower"], 2),
            confidence_upper=round(pred["upper"], 2),
        )
        results.append(result)

    # Also predict total
    total_pred = _forecast_series(total_monthly, target_month, n_months)
    if total_pred:
        results.append(PredictionResult(
            category_id=None,
            category_name=None,
            prediction_date=target_month,
            predicted_amount=round(total_pred["predicted"], 2),
            confidence_lower=round(total_pred["lower"], 2),
            confidence_upper=round(total_pred["upper"], 2),
        ))

    # Delete old predictions for this month
    db.query(SpendingPrediction).filter(
        and_(
            SpendingPrediction.user_id == user_id,
            SpendingPrediction.prediction_date == target_month,
        )
    ).delete()
    db.flush()

    # Persist
    for r in results:
        pred = SpendingPrediction(
            id=uuid.uuid4(),
            user_id=user_id,
            category_id=r.category_id,
            prediction_date=r.prediction_date,
            predicted_amount=r.predicted_amount,
            confidence_lower=r.confidence_lower,
            confidence_upper=r.confidence_upper,
            model_version=settings.model_version,
            model_parameters={"method": "exponential_smoothing", "months_history": n_months},
        )
        db.add(pred)

    db.commit()
    logger.info(f"User {user_id}: generated {len(results)} predictions for {target_month}")
    return results


def _forecast_series(
    monthly: dict[date, float], target: date, n_months: int
) -> dict | None:
    """Forecast using exponential smoothing with confidence interval."""
    # Build ordered series filling missing months with 0
    months = []
    current = _subtract_months(target, n_months)
    while current < target:
        months.append(current)
        current = _add_month(current)

    values = np.array([monthly.get(m, 0.0) for m in months])

    # Need at least 3 non-zero values
    if np.count_nonzero(values) < 3:
        return None

    try:
        from statsmodels.tsa.holtwinters import SimpleExpSmoothing
        model = SimpleExpSmoothing(values, initialization_method="estimated")
        fit = model.fit(optimized=True)
        predicted = float(fit.forecast(1)[0])
    except Exception:
        # Fallback: weighted moving average (recent months weight more)
        weights = np.array([1, 1, 2, 2, 3, 3])[:len(values)]
        weights = weights[-len(values):]
        predicted = float(np.average(values, weights=weights))

    # Confidence interval based on residual std
    std = float(np.std(values)) if len(values) > 1 else predicted * 0.3
    z = 1.96  # ~95% confidence

    predicted = max(predicted, 0)
    lower = max(predicted - z * std, 0)
    upper = predicted + z * std

    return {"predicted": predicted, "lower": lower, "upper": upper}


def _subtract_months(d: date, months: int) -> date:
    month = d.month - months
    year = d.year
    while month <= 0:
        month += 12
        year -= 1
    return date(year, month, 1)


def _add_month(d: date) -> date:
    if d.month == 12:
        return date(d.year + 1, 1, 1)
    return date(d.year, d.month + 1, 1)

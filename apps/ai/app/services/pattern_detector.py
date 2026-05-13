"""
Pattern Detector — Detects spending patterns from transaction history.

Detects: SEASONAL, TREND, ANOMALY, RECURRING, CATEGORY_SHIFT,
         INCOME_CHANGE, LIFESTYLE_CHANGE.
"""

import uuid
import json
import logging
from collections import defaultdict
from datetime import date, timedelta
from decimal import Decimal

import numpy as np
from sqlalchemy import and_, func, extract
from sqlalchemy.orm import Session

from app.config import settings
from app.models.models import SpendingPattern, Transaction, Category
from app.schemas.schemas import PatternResult

logger = logging.getLogger(__name__)


def detect_patterns(db: Session, user_id: uuid.UUID) -> list[PatternResult]:
    """Run all pattern detectors and persist results."""
    # Deactivate old patterns
    db.query(SpendingPattern).filter(
        and_(SpendingPattern.user_id == user_id, SpendingPattern.is_active == True)
    ).update({"is_active": False})
    db.flush()

    # Get 6 months of transactions
    end = date.today()
    start = end - timedelta(days=180)

    txs = (
        db.query(Transaction)
        .filter(
            and_(
                Transaction.user_id == user_id,
                Transaction.transaction_date.between(start, end),
                Transaction.is_paid == True,
            )
        )
        .order_by(Transaction.transaction_date)
        .all()
    )

    if len(txs) < 10:
        logger.info(f"User {user_id}: only {len(txs)} txs, skipping pattern detection")
        return []

    results = []
    results.extend(_detect_anomalies(txs, user_id, start, end))
    results.extend(_detect_trends(txs, user_id, start, end))
    results.extend(_detect_recurring(txs, user_id, start, end))
    results.extend(_detect_category_shift(txs, user_id, start, end))

    # Persist
    for r in results:
        pattern = SpendingPattern(
            id=uuid.uuid4(),
            user_id=user_id,
            pattern_type=r.pattern_type,
            description=r.description,
            pattern_data=r.pattern_data,
            significance_score=round(r.significance_score, 4),
            detected_from=r.detected_from,
            detected_to=r.detected_to,
            is_active=True,
            model_version=settings.model_version,
        )
        db.add(pattern)

    db.commit()
    logger.info(f"User {user_id}: detected {len(results)} patterns")
    return results


def _detect_anomalies(
    txs: list, user_id: uuid.UUID, start: date, end: date
) -> list[PatternResult]:
    """Detect anomalous spending days using z-score."""
    results = []
    # Group expenses by day
    daily = defaultdict(float)
    for tx in txs:
        if tx.type == "EXPENSE":
            daily[tx.transaction_date] += float(tx.amount)

    if len(daily) < 14:
        return results

    values = np.array(list(daily.values()))
    mean = np.mean(values)
    std = np.std(values)

    if std == 0:
        return results

    for dt, val in daily.items():
        z = (val - mean) / std
        if abs(z) >= settings.pattern_anomaly_z_threshold:
            sig = min(abs(z) / 5.0, 1.0)  # normalize to 0-1
            results.append(PatternResult(
                pattern_type="ANOMALY",
                description=f"Gasto incomum de R$ {val:.2f} em {dt.strftime('%d/%m/%Y')} "
                            f"({z:.1f}x acima da média diária de R$ {mean:.2f})",
                pattern_data={"date": str(dt), "amount": val, "z_score": round(z, 2), "daily_mean": round(mean, 2)},
                significance_score=round(sig, 4),
                detected_from=dt,
                detected_to=dt,
            ))

    return results[:5]  # Top 5 anomalies


def _detect_trends(
    txs: list, user_id: uuid.UUID, start: date, end: date
) -> list[PatternResult]:
    """Detect increasing/decreasing monthly spending trends."""
    results = []
    # Group by month
    monthly = defaultdict(float)
    for tx in txs:
        if tx.type == "EXPENSE":
            key = tx.transaction_date.replace(day=1)
            monthly[key] += float(tx.amount)

    if len(monthly) < 3:
        return results

    sorted_months = sorted(monthly.keys())
    values = [monthly[m] for m in sorted_months]

    # Simple linear regression
    x = np.arange(len(values))
    if len(x) < 3:
        return results

    slope, intercept = np.polyfit(x, values, 1)
    mean_val = np.mean(values)

    if mean_val == 0:
        return results

    # Significance: how strong is the trend relative to mean
    trend_pct = (slope / mean_val) * 100
    sig = min(abs(trend_pct) / 30.0, 1.0)

    if sig >= settings.pattern_min_significance:
        if slope > 0:
            results.append(PatternResult(
                pattern_type="TREND",
                description=f"Seus gastos estão subindo ~{abs(trend_pct):.0f}% ao mês. "
                            f"Média: R$ {mean_val:.0f}/mês.",
                pattern_data={
                    "direction": "INCREASING",
                    "slope_per_month": round(slope, 2),
                    "trend_pct": round(trend_pct, 1),
                    "monthly_values": {str(k): round(v, 2) for k, v in zip(sorted_months, values)},
                },
                significance_score=round(sig, 4),
                detected_from=sorted_months[0],
                detected_to=sorted_months[-1],
            ))
        else:
            results.append(PatternResult(
                pattern_type="TREND",
                description=f"Seus gastos estão caindo ~{abs(trend_pct):.0f}% ao mês. "
                            f"Média: R$ {mean_val:.0f}/mês.",
                pattern_data={
                    "direction": "DECREASING",
                    "slope_per_month": round(slope, 2),
                    "trend_pct": round(trend_pct, 1),
                    "monthly_values": {str(k): round(v, 2) for k, v in zip(sorted_months, values)},
                },
                significance_score=round(sig, 4),
                detected_from=sorted_months[0],
                detected_to=sorted_months[-1],
            ))

    return results


def _detect_recurring(
    txs: list, user_id: uuid.UUID, start: date, end: date
) -> list[PatternResult]:
    """Detect recurring amounts that aren't flagged as recurring."""
    results = []
    # Group by (description_lower, rounded_amount)
    groups = defaultdict(list)
    for tx in txs:
        if tx.type == "EXPENSE" and not tx.is_recurring:
            key = (tx.description.lower().strip(), round(float(tx.amount), 0))
            groups[key].append(tx.transaction_date)

    for (desc, amount), dates in groups.items():
        if len(dates) < 3:
            continue
        # Check if dates are roughly evenly spaced
        dates_sorted = sorted(dates)
        intervals = [(dates_sorted[i + 1] - dates_sorted[i]).days for i in range(len(dates_sorted) - 1)]
        avg_interval = np.mean(intervals)
        std_interval = np.std(intervals)

        if avg_interval > 0 and std_interval / avg_interval < 0.3:
            sig = min(len(dates) / 6.0, 1.0) * (1 - std_interval / avg_interval)
            if sig >= settings.pattern_min_significance:
                freq = "mensal" if 25 <= avg_interval <= 35 else f"a cada {avg_interval:.0f} dias"
                results.append(PatternResult(
                    pattern_type="RECURRING",
                    description=f'"{desc}" de R$ {amount:.0f} aparece {freq} '
                                f"({len(dates)} ocorrências). Considere marcar como recorrente.",
                    pattern_data={
                        "description": desc,
                        "amount": amount,
                        "occurrences": len(dates),
                        "avg_interval_days": round(avg_interval, 1),
                        "dates": [str(d) for d in dates_sorted],
                    },
                    significance_score=round(sig, 4),
                    detected_from=dates_sorted[0],
                    detected_to=dates_sorted[-1],
                ))

    return results[:5]


def _detect_category_shift(
    txs: list, user_id: uuid.UUID, start: date, end: date
) -> list[PatternResult]:
    """Detect categories where spending changed significantly."""
    results = []
    mid = start + (end - start) / 2

    # Split into first half and second half
    first_half = defaultdict(float)
    second_half = defaultdict(float)
    cat_names = {}

    for tx in txs:
        if tx.type != "EXPENSE" or not tx.category_id:
            continue
        cid = str(tx.category_id)
        cat_names[cid] = tx.category.name if tx.category else cid
        if tx.transaction_date < mid:
            first_half[cid] += float(tx.amount)
        else:
            second_half[cid] += float(tx.amount)

    all_cats = set(first_half.keys()) | set(second_half.keys())
    for cid in all_cats:
        v1 = first_half.get(cid, 0)
        v2 = second_half.get(cid, 0)
        if v1 == 0 and v2 == 0:
            continue
        base = max(v1, v2, 1)
        change_pct = ((v2 - v1) / base) * 100
        sig = min(abs(change_pct) / 80.0, 1.0)

        if sig >= settings.pattern_min_significance and abs(change_pct) >= 40:
            name = cat_names.get(cid, "Categoria")
            direction = "aumentou" if change_pct > 0 else "diminuiu"
            results.append(PatternResult(
                pattern_type="CATEGORY_SHIFT",
                description=f'Gasto em "{name}" {direction} {abs(change_pct):.0f}% '
                            f"nos últimos 3 meses comparado aos anteriores.",
                pattern_data={
                    "category_id": cid,
                    "category_name": name,
                    "first_half_total": round(v1, 2),
                    "second_half_total": round(v2, 2),
                    "change_pct": round(change_pct, 1),
                },
                significance_score=round(sig, 4),
                detected_from=start,
                detected_to=end,
            ))

    return sorted(results, key=lambda r: r.significance_score, reverse=True)[:3]

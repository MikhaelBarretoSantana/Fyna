"""
Testes unitários do InvestmentAdvisor.
"""

import uuid
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest

from app.services.investment_advisor import (
    _future_value,
    _tolerance_label,
    ALLOCATIONS,
    RETURN_ESTIMATES,
)


# ─── _future_value ───────────────────────────────────────────────────────────


class TestFutureValue:

    def test_investimento_zero_retorna_zero(self):
        assert _future_value(0, 12.0, 5) == 0.0

    def test_taxa_zero_retorna_soma_simples(self):
        result = _future_value(100, 0.0, 5)
        assert result == pytest.approx(100 * 60, rel=1e-6)

    def test_valores_positivos_crescem(self):
        result = _future_value(100, 12.0, 5)
        assert result > 100 * 60, "Valor futuro deve ser maior que soma simples com juros"

    def test_periodo_maior_gera_valor_maior(self):
        v5 = _future_value(500, 10.0, 5)
        v10 = _future_value(500, 10.0, 10)
        assert v10 > v5

    def test_taxa_maior_gera_valor_maior(self):
        v_conservador = _future_value(500, 8.5, 5)
        v_agressivo = _future_value(500, 18.0, 5)
        assert v_agressivo > v_conservador


# ─── _tolerance_label ────────────────────────────────────────────────────────


class TestToleranceLabel:

    def test_labels_conhecidos(self):
        casos = {
            "CONSERVATIVE": "Conservador",
            "MODERATE": "Moderado",
            "AGGRESSIVE": "Agressivo",
        }
        for key, expected in casos.items():
            assert _tolerance_label(key) == expected

    def test_label_desconhecido_retorna_o_proprio_valor(self):
        assert _tolerance_label("UNKNOWN") == "UNKNOWN"


# ─── ALLOCATIONS sanity check ────────────────────────────────────────────────


class TestAllocations:

    def test_todos_perfis_somam_100(self):
        for profile, alloc in ALLOCATIONS.items():
            total = sum(alloc.values())
            assert total == 100, f"Perfil {profile} soma {total} (esperado 100)"

    def test_todos_perfis_tem_retorno_estimado(self):
        for profile in ALLOCATIONS:
            assert profile in RETURN_ESTIMATES, f"Perfil {profile} sem retorno estimado"

    def test_agressivo_tem_maior_retorno_que_conservador(self):
        assert RETURN_ESTIMATES["AGGRESSIVE"] > RETURN_ESTIMATES["CONSERVATIVE"]


# ─── generate_recommendations ────────────────────────────────────────────────


class TestGenerateRecommendations:

    def _make_db(self, risk_profile=None, income=3000.0, expense=2000.0, goals=None):
        db = MagicMock()

        from app.models.models import RiskProfile, Transaction, FinancialGoal, Account, InvestmentRecommendation

        # Risk profile query
        risk_query = MagicMock()
        risk_query.filter.return_value = risk_query
        risk_query.first.return_value = risk_profile

        # Income/expense transactions
        income_tx = MagicMock()
        income_tx.amount = Decimal(str(income))
        expense_tx = MagicMock()
        expense_tx.amount = Decimal(str(expense))

        tx_query = MagicMock()
        tx_query.filter.return_value = tx_query
        # First call = income, second call = expense
        tx_query.all.side_effect = [[income_tx], [expense_tx]]

        # Goals
        goal_query = MagicMock()
        goal_query.filter.return_value = goal_query
        goal_query.all.return_value = goals or []

        # Accounts
        account = MagicMock()
        account.current_balance = Decimal("5000")
        account.is_active = True
        acct_query = MagicMock()
        acct_query.filter.return_value = acct_query
        acct_query.all.return_value = [account]

        # Delete recommendations
        del_query = MagicMock()
        del_query.filter.return_value = del_query
        del_query.delete.return_value = None

        def query_side_effect(model):
            if model is RiskProfile:
                return risk_query
            if model is Transaction:
                return tx_query
            if model is FinancialGoal:
                return goal_query
            if model is Account:
                return acct_query
            if model is InvestmentRecommendation:
                return del_query
            return MagicMock()

        db.query.side_effect = query_side_effect
        db.flush = MagicMock()
        db.add = MagicMock()
        db.commit = MagicMock()
        return db

    def _make_risk_profile(self, tolerance="MODERATE", score=50.0, emergency=10000.0):
        rp = MagicMock()
        rp.id = uuid.uuid4()
        rp.risk_tolerance = tolerance
        rp.calculated_score = Decimal(str(score))
        rp.emergency_fund = Decimal(str(emergency))
        return rp

    def test_sem_perfil_de_risco_retorna_recomendacao_basica(self):
        from app.services.investment_advisor import generate_recommendations

        db = self._make_db(risk_profile=None)
        results = generate_recommendations(db, uuid.uuid4())

        assert len(results) == 1
        assert results[0].recommendation_type == "RISK_ADJUSTMENT"
        assert "perfil de risco" in results[0].description.lower()

    def test_com_perfil_moderado_retorna_alocacao(self):
        from app.services.investment_advisor import generate_recommendations

        rp = self._make_risk_profile("MODERATE", 50.0, 20000.0)
        db = self._make_db(risk_profile=rp, income=5000.0, expense=3000.0)

        results = generate_recommendations(db, uuid.uuid4())

        types = [r.recommendation_type for r in results]
        assert "ASSET_ALLOCATION" in types
        assert "NEW_INVESTMENT" in types

    def test_reserva_insuficiente_gera_alerta(self):
        from app.services.investment_advisor import generate_recommendations

        # Reserva de R$500 com gasto de R$3000/mês = 0.5 meses (muito abaixo de 6)
        rp = self._make_risk_profile("MODERATE", 50.0, emergency=500.0)
        db = self._make_db(risk_profile=rp, income=5000.0, expense=3000.0)

        results = generate_recommendations(db, uuid.uuid4())

        risk_alerts = [r for r in results if r.recommendation_type == "RISK_ADJUSTMENT"
                       and "reserva" in r.title.lower()]
        assert len(risk_alerts) >= 1

    def test_gastos_acima_da_receita_gera_alerta(self):
        from app.services.investment_advisor import generate_recommendations

        rp = self._make_risk_profile("MODERATE", 50.0, emergency=30000.0)
        db = self._make_db(risk_profile=rp, income=2000.0, expense=3500.0)

        results = generate_recommendations(db, uuid.uuid4())

        deficit_alerts = [r for r in results if r.recommendation_type == "RISK_ADJUSTMENT"
                          and "gastos" in r.title.lower()]
        assert len(deficit_alerts) >= 1

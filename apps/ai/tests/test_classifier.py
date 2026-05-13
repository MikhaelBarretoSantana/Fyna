"""
Testes unitários do TransactionClassifier.

Usa mocks para o banco de dados — não requer PostgreSQL.
"""

import uuid
from decimal import Decimal
from unittest.mock import MagicMock, patch

import numpy as np
import pytest

from app.services.classifier import _encode_texts, _PTBR_STOPWORDS


# ─── _encode_texts (TF-IDF fallback) ────────────────────────────────────────


class TestEncodeTFIDF:
    """Testa o fallback TF-IDF sem precisar do modelo transformer."""

    def setup_method(self):
        # Força uso do TF-IDF (sem transformer)
        import app.services.classifier as clf_module
        self._original = clf_module._use_tfidf_fallback
        clf_module._use_tfidf_fallback = True
        clf_module._embedding_model = None

    def teardown_method(self):
        import app.services.classifier as clf_module
        clf_module._use_tfidf_fallback = self._original

    def test_retorna_array_com_dimensoes_corretas(self):
        texts = ["almoço restaurante", "mercado supermercado", "salário pagamento"]
        result = _encode_texts(texts)
        assert isinstance(result, np.ndarray)
        assert result.shape[0] == 3

    def test_vetores_sao_normalizados(self):
        texts = ["uber taxi", "salário mensal", "conta de luz energia elétrica"]
        result = _encode_texts(texts)
        norms = np.linalg.norm(result, axis=1)
        np.testing.assert_allclose(norms, 1.0, atol=1e-6)

    def test_textos_similares_tem_vetores_proximos(self):
        texts = [
            "mercado supermercado compras",
            "compras mercado alimentação",
            "salário pagamento renda",
        ]
        result = _encode_texts(texts)
        sim_similar = float(np.dot(result[0], result[1]))
        sim_different = float(np.dot(result[0], result[2]))
        assert sim_similar > sim_different, (
            "Textos similares devem ter maior similaridade coseno"
        )

    def test_stopwords_ptbr_nao_vazias(self):
        assert len(_PTBR_STOPWORDS) > 20
        # Palavras mais comuns devem estar na lista
        for word in ["de", "e", "o", "a", "para", "com"]:
            assert word in _PTBR_STOPWORDS, f"Stopword '{word}' ausente"

    def test_texto_unico_nao_gera_erro(self):
        texts = ["único texto"]
        result = _encode_texts(texts)
        assert result.shape[0] == 1

    def test_texto_com_acentos(self):
        texts = ["café padaria", "farmácia remédio", "água mineral"]
        result = _encode_texts(texts)
        assert result.shape[0] == 3
        assert not np.any(np.isnan(result))


# ─── classify_transaction (integração com DB mockado) ───────────────────────


class TestClassifyTransaction:

    @patch("app.services.classifier._use_tfidf_fallback", True)
    @patch("app.services.classifier._embedding_model", None)
    def test_retorna_resultado_com_categoria_sugerida(self):
        from app.services.classifier import classify_transaction

        # Mock da session do DB
        db = MagicMock()

        # Categorias mockadas
        cat_alimentacao = MagicMock()
        cat_alimentacao.id = uuid.uuid4()
        cat_alimentacao.name = "Alimentação"
        cat_alimentacao.type = "EXPENSE"
        cat_alimentacao.is_active = True
        cat_alimentacao.display_order = 1
        cat_alimentacao.user_id = None

        cat_transporte = MagicMock()
        cat_transporte.id = uuid.uuid4()
        cat_transporte.name = "Transporte"
        cat_transporte.type = "EXPENSE"
        cat_transporte.is_active = True
        cat_transporte.display_order = 2
        cat_transporte.user_id = None

        # Configura mock de query encadeado para categorias
        category_query = MagicMock()
        category_query.filter.return_value = category_query
        category_query.order_by.return_value = category_query
        category_query.all.return_value = [cat_alimentacao, cat_transporte]

        # Configura mock de query para classificações confirmadas
        confirmed_query = MagicMock()
        confirmed_query.join.return_value = confirmed_query
        confirmed_query.filter.return_value = confirmed_query
        confirmed_query.limit.return_value = confirmed_query
        confirmed_query.all.return_value = []

        # AIClassification mock (para o save)
        db.add = MagicMock()
        db.commit = MagicMock()
        db.refresh = MagicMock()

        from app.models.models import Category, AIClassification
        db.query.side_effect = lambda model: (
            category_query if model is Category else confirmed_query
        )

        tx_id = uuid.uuid4()
        user_id = uuid.uuid4()

        result = classify_transaction(
            db=db,
            transaction_id=tx_id,
            user_id=user_id,
            description="almoço no restaurante",
            amount=45.0,
            transaction_type="EXPENSE",
        )

        assert result.transaction_id == tx_id
        assert result.confidence_score >= 0.0
        assert result.suggested_category_id is not None
        db.commit.assert_called_once()

    @patch("app.services.classifier._use_tfidf_fallback", True)
    @patch("app.services.classifier._embedding_model", None)
    def test_sem_categorias_retorna_resultado_sem_sugestao(self):
        from app.services.classifier import classify_transaction

        db = MagicMock()
        from app.models.models import Category, AIClassification

        empty_query = MagicMock()
        empty_query.filter.return_value = empty_query
        empty_query.order_by.return_value = empty_query
        empty_query.all.return_value = []

        db.query.return_value = empty_query

        result = classify_transaction(
            db=db,
            transaction_id=uuid.uuid4(),
            user_id=uuid.uuid4(),
            description="compra",
            amount=10.0,
            transaction_type="EXPENSE",
        )

        assert result.confidence_score == 0.0
        assert result.suggested_category_id is None


# ─── Auth: verify_internal_key ───────────────────────────────────────────────


class TestVerifyInternalKey:

    def test_chave_valida_nao_levanta_excecao(self):
        from fastapi import HTTPException
        from app.api.routes import verify_internal_key
        from app.config import settings

        # Não deve levantar exceção
        try:
            verify_internal_key(x_internal_key=settings.internal_api_key)
        except HTTPException:
            pytest.fail("verify_internal_key levantou HTTPException com chave válida")

    def test_chave_invalida_levanta_401(self):
        from fastapi import HTTPException
        from app.api.routes import verify_internal_key

        with pytest.raises(HTTPException) as exc_info:
            verify_internal_key(x_internal_key="chave-errada")

        assert exc_info.value.status_code == 401

"""
Transaction Classifier — Classifies transactions into categories.

Uses sentence-transformers for multilingual embeddings (PT-BR optimized),
with TF-IDF fallback when the transformer model is unavailable.
Learns from user corrections (was_corrected=true) to improve over time.
"""

import uuid
import json
import logging
from typing import Optional

import numpy as np
from sqlalchemy import and_
from sqlalchemy.orm import Session

from app.config import settings
from app.models.models import (
    AIClassification, Category, Transaction,
)
from app.schemas.schemas import ClassificationResult

logger = logging.getLogger(__name__)

# ─── Embedding model (lazy-loaded) ───
_embedding_model = None
_use_tfidf_fallback = False


def _get_embedding_model():
    global _embedding_model, _use_tfidf_fallback
    if _embedding_model is not None:
        return _embedding_model

    try:
        from sentence_transformers import SentenceTransformer
        _embedding_model = SentenceTransformer(settings.classifier_model)
        logger.info(f"Loaded embedding model: {settings.classifier_model}")
        return _embedding_model
    except Exception as e:
        logger.warning(f"Could not load transformer model: {e}. Using TF-IDF fallback.")
        _use_tfidf_fallback = True
        return None


# Stopwords em PT-BR para melhorar o TF-IDF fallback.
# Cobre as palavras mais comuns que não carregam significado semântico financeiro.
_PTBR_STOPWORDS = [
    "a", "ao", "aos", "as", "até", "com", "como", "da", "das", "de", "dela",
    "delas", "dele", "deles", "do", "dos", "e", "é", "ela", "elas", "ele",
    "eles", "em", "entre", "era", "essa", "essas", "esse", "esses", "esta",
    "estas", "este", "estes", "eu", "foi", "for", "foram", "há", "isso",
    "isto", "já", "lhe", "lhes", "mais", "mas", "me", "mesmo", "meu",
    "minha", "muito", "na", "nas", "não", "nem", "no", "nos", "o", "os",
    "ou", "para", "pela", "pelas", "pelo", "pelos", "por", "que", "se",
    "sem", "seu", "seus", "sua", "suas", "são", "também", "te", "tem",
    "ter", "teu", "tua", "um", "uma", "umas", "uns", "você", "vocês",
]


def _encode_texts(texts: list[str]) -> np.ndarray:
    """Encode texts to vectors using transformer or TF-IDF."""
    model = _get_embedding_model()

    if model is not None and not _use_tfidf_fallback:
        return model.encode(texts, normalize_embeddings=True, show_progress_bar=False)

    # TF-IDF fallback otimizado para PT-BR
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.preprocessing import normalize
    vectorizer = TfidfVectorizer(
        max_features=5000,
        ngram_range=(1, 2),
        strip_accents="unicode",
        analyzer="word",
        stop_words=_PTBR_STOPWORDS,
        sublinear_tf=True,  # log(1 + tf) — reduz impacto de termos muito frequentes
    )
    matrix = vectorizer.fit_transform(texts)
    return normalize(matrix).toarray()


def classify_transaction(
    db: Session,
    transaction_id: uuid.UUID,
    user_id: uuid.UUID,
    description: str,
    amount: float,
    transaction_type: str,
) -> ClassificationResult:
    """
    Classify a single transaction by finding the closest category
    based on embedding similarity.
    """
    # 1. Get user's categories for this transaction type
    categories = (
        db.query(Category)
        .filter(
            and_(
                Category.type == transaction_type,
                Category.is_active == True,
                (Category.user_id == user_id) | (Category.user_id.is_(None)),
            )
        )
        .order_by(Category.display_order)
        .all()
    )

    if not categories:
        return ClassificationResult(
            transaction_id=transaction_id,
            confidence_score=0.0,
            model_version=settings.model_version,
        )

    # 2. Build corpus: category names + confirmed examples
    cat_labels = [cat.name for cat in categories]
    # Enrich with past confirmed descriptions for each category
    confirmed = (
        db.query(AIClassification)
        .join(Transaction, AIClassification.transaction_id == Transaction.id)
        .filter(
            and_(
                Transaction.user_id == user_id,
                AIClassification.was_confirmed == True,
                AIClassification.confirmed_category_id.isnot(None),
            )
        )
        .limit(200)
        .all()
    )

    # Map category_id -> list of confirmed descriptions
    cat_examples: dict[str, list[str]] = {}
    for c in confirmed:
        cid = str(c.confirmed_category_id)
        cat_examples.setdefault(cid, []).append(c.original_text)

    # Build representative text per category: name + up to 5 examples
    cat_texts = []
    for cat in categories:
        examples = cat_examples.get(str(cat.id), [])[:5]
        combined = cat.name
        if examples:
            combined += " | " + " | ".join(examples)
        cat_texts.append(combined)

    # 3. Encode description + all category representatives
    all_texts = [description] + cat_texts
    embeddings = _encode_texts(all_texts)
    desc_vec = embeddings[0]
    cat_vecs = embeddings[1:]

    # 4. Cosine similarity
    similarities = np.dot(cat_vecs, desc_vec)
    best_idx = int(np.argmax(similarities))
    best_score = float(similarities[best_idx])

    if best_score < settings.classifier_confidence_threshold:
        # Below threshold — still suggest but with low confidence
        pass

    best_category = categories[best_idx]

    # 5. Persist classification
    classification = AIClassification(
        id=uuid.uuid4(),
        transaction_id=transaction_id,
        suggested_category_id=best_category.id,
        confidence_score=round(best_score, 4),
        original_text=description[:500],
        model_version=settings.model_version,
        feature_vector={"similarities": similarities.tolist()},
    )
    db.add(classification)
    db.commit()
    db.refresh(classification)

    logger.info(
        f"Classified tx={transaction_id} → "
        f"category='{best_category.name}' (score={best_score:.3f})"
    )

    return ClassificationResult(
        transaction_id=transaction_id,
        suggested_category_id=best_category.id,
        suggested_category_name=best_category.name,
        confidence_score=round(best_score, 4),
        model_version=settings.model_version,
    )


def is_model_loaded() -> bool:
    """Check if the embedding model is ready."""
    model = _get_embedding_model()
    return model is not None or _use_tfidf_fallback

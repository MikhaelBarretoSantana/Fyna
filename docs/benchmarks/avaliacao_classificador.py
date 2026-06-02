"""
Avaliacao do classificador — Fyna.

Gera N transacoes sinteticas com rotulo verdadeiro, envia cada uma ao
backend Spring (POST /api/v1/transactions SEM categoryId — o que dispara
classificacao async via @Async + fyna-ai), e depois consulta
GET /api/v1/ai/classifications/transaction/{id} para coletar a predicao.

Saidas:
- resultados_brutos.csv          (1 linha por transacao: rotulo_real, predicao, latencias)
- metricas_por_categoria.csv     (precision/recall/f1 por categoria)
- matriz_confusao.png            (heatmap normalizado por linha)
- relatorio_classificador.txt    (sumario com metricas globais)

Variaveis de ambiente:
- BASE_URL          ex.: http://localhost:8080
- JWT_TOKEN         token JWT valido
- ACCOUNT_ID        UUID de uma conta existente
- N_SAMPLES         (opcional) tamanho do corpus, padrao 600
- POLL_RETRIES      (opcional) tentativas para buscar a classificacao, padrao 10
- POLL_INTERVAL     (opcional) intervalo em segundos entre tentativas, padrao 1.0
"""
from __future__ import annotations

import json
import os
import random
import sys
import time
import unicodedata
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Optional

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import requests
import seaborn as sns
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)


def _env(name: str, default: Optional[str] = None) -> str:
    val = os.environ.get(name, default)
    if val is None:
        print(f"[ERRO] variavel de ambiente {name} nao definida.", file=sys.stderr)
        sys.exit(1)
    return val


BASE_URL = _env("BASE_URL", "http://localhost:8080").rstrip("/")
JWT_TOKEN = _env("JWT_TOKEN")
ACCOUNT_ID = _env("ACCOUNT_ID")
N_SAMPLES = int(os.environ.get("N_SAMPLES", "600"))
POLL_RETRIES = int(os.environ.get("POLL_RETRIES", "10"))
POLL_INTERVAL = float(os.environ.get("POLL_INTERVAL", "1.0"))

SESSION = requests.Session()
SESSION.headers.update({
    "Authorization": f"Bearer {JWT_TOKEN}",
    "Content-Type": "application/json",
})


# ─────────────────── Corpus sintetico (PT-BR) ───────────────────
# Cada item: (descricao, rotulo_real_categoria_canonica, tipo)
# Os rotulos sao "canonicos" — comparados case-insensitive com o nome retornado
# pelo classificador. Ajuste se sua base usar nomes diferentes.

CORPUS_TEMPLATES: list[tuple[list[str], str, str]] = [
    # ─── EXPENSE ─── (categorias canônicas alinhadas ao seed global do banco) ───
    ([
        "Almoço restaurante", "Jantar restaurante japonês", "Pizza delivery sexta",
        "Lanchonete shopping", "iFood almoço", "Restaurante self-service",
        "Hamburgueria centro", "Sushi rodízio", "Bar da esquina jantar",
        "Restaurante a la carte",
    ], "Restaurantes", "EXPENSE"),
    ([
        "Uber centro", "99 corrida noite", "Uber pool aeroporto",
        "99 corrida tarde", "Cabify viagem", "Uber Black evento",
    ], "Aplicativos de Transporte", "EXPENSE"),
    ([
        "Combustível posto Shell", "Abastecer gasolina Ipiranga",
        "Diesel posto rodovia", "Etanol BR posto", "Gasolina aditivada",
        "Combustível viagem", "Posto BR gasolina",
    ], "Combustível", "EXPENSE"),
    ([
        "Recarga bilhete único", "Passagem ônibus urbano",
        "Metrô passagem", "Bilhete trem CPTM", "VT cartão recarga",
        "Ônibus intermunicipal", "Cartão BOM recarga",
    ], "Transporte Público", "EXPENSE"),
    ([
        "Supermercado semana", "Atacadão mensal compras",
        "Carrefour compras mês", "Compras Pão de Açúcar",
        "Extra hipermercado", "Assaí atacadista", "Sams Club compras",
        "Hortifrúti feira semana", "Sacolão da feira", "Açougue boi",
    ], "Supermercado", "EXPENSE"),
    ([
        "Conta de luz CPFL", "Energia Enel", "Conta luz Light",
        "Tarifa energia elétrica", "Conta elétrica mês",
    ], "Energia", "EXPENSE"),
    ([
        "Conta de água Sabesp", "Tarifa água Sanepar",
        "Conta água mensal", "Saneamento básico", "Cosan água",
    ], "Água", "EXPENSE"),
    ([
        "Internet Vivo Fibra", "Net Claro internet",
        "TIM Live banda larga", "Internet Oi fibra",
        "Provedor local internet", "Plano internet 500mb",
    ], "Internet", "EXPENSE"),
    ([
        "Aluguel mensal apartamento", "Locação imóvel",
        "Aluguel kitnet", "Aluguel casa", "Pagamento aluguel imobiliária",
    ], "Aluguel", "EXPENSE"),
    ([
        "Condomínio prédio", "Taxa condominial",
        "Boleto condomínio", "Condomínio mensal", "Cota condominial",
    ], "Condomínio", "EXPENSE"),
    ([
        "Farmácia remédio", "Drogaria São Paulo",
        "Pague Menos remédios", "Drogasil compra",
        "Farmácia Popular remédio", "Antibiótico farmácia",
        "Vitaminas farmácia",
    ], "Farmácia", "EXPENSE"),
    ([
        "Plano de saúde Unimed", "Mensalidade Amil",
        "Bradesco Saúde mensal", "SulAmérica plano saúde",
        "NotreDame Intermédica", "Hapvida mensalidade",
    ], "Plano de Saúde", "EXPENSE"),
    ([
        "Consulta médica particular", "Dentista limpeza",
        "Exames laboratório", "Óculos ótica",
        "Fisioterapia sessão", "Psicólogo consulta",
        "Dermatologista consulta", "Acupuntura sessão",
    ], "Saúde", "EXPENSE"),
    ([
        "Cinema ingresso", "Show banda", "Bar com amigos",
        "Festa balada", "Teatro peça", "Parque ingresso",
        "Boliche partida", "Karaokê noite",
    ], "Lazer", "EXPENSE"),
    ([
        "Netflix mensalidade", "Spotify premium",
        "Disney Plus assinatura", "HBO Max mensal",
        "Amazon Prime Video", "Apple TV+ assinatura",
        "YouTube Premium mensal",
    ], "Streaming", "EXPENSE"),
    ([
        "Steam jogo PC", "PlayStation Store jogo",
        "Xbox Game Pass mensal", "Nintendo eShop jogo",
        "Epic Games compra", "Jogo mobile in-app",
    ], "Jogos", "EXPENSE"),
    ([
        "Mensalidade academia", "Smart Fit mensalidade",
        "Bio Ritmo academia", "Anuidade academia",
        "Academia plano trimestral",
    ], "Academia", "EXPENSE"),
    ([
        "Curso de inglês Cultura Inglesa", "Udemy curso online",
        "Workshop pago presencial", "Aula particular violão",
        "Coursera assinatura", "Alura assinatura anual",
        "Curso de programação",
    ], "Cursos", "EXPENSE"),
    ([
        "Mensalidade faculdade", "Material escolar filhos",
        "Apostila concurso", "Anuidade colégio",
        "Mensalidade escola particular",
    ], "Educação", "EXPENSE"),
    ([
        "Livro técnico programação", "Livraria Saraiva livro",
        "Amazon livro físico", "Livro romance", "Compra ebook Kindle",
    ], "Livros", "EXPENSE"),
    # ─── INCOME ───
    ([
        "Salário mensal empresa", "Pagamento salário",
        "Bônus trimestral", "Décimo terceiro",
        "Adiantamento salarial", "PLR participação",
        "Horas extras", "Comissão venda mensal",
    ], "Salário", "INCOME"),
    ([
        "Pagamento freelance projeto", "Job freelancer site",
        "Trabalho extra freelance", "Projeto freela design",
        "Recebimento freelance código",
    ], "Freelance", "INCOME"),
    ([
        "Rendimento poupança", "Dividendo ação",
        "Juros CDB", "Rendimento Tesouro Direto",
        "Aluguel recebido imóvel", "Resgate fundo investimento",
        "Cupom LCI", "FII rendimento mensal", "Lucro venda ação",
    ], "Investimentos", "INCOME"),
    ([
        "Reembolso despesa empresa", "Reembolso plano saúde",
        "Reembolso viagem trabalho", "Estorno cartão crédito",
        "Reembolso emergência médica",
    ], "Reembolso", "INCOME"),
]


@dataclass
class Sample:
    description: str
    expected_category: str
    transaction_type: str


def build_corpus(n: int) -> list[Sample]:
    """Gera N amostras balanceadas entre as categorias do corpus."""
    samples: list[Sample] = []
    for descs, category, tx_type in CORPUS_TEMPLATES:
        for desc in descs:
            samples.append(Sample(desc, category, tx_type))
    random.seed(42)
    random.shuffle(samples)

    # Replica ate atingir N e adiciona pequenas variantes para nao virar puro overfit
    out: list[Sample] = []
    i = 0
    while len(out) < n:
        base = samples[i % len(samples)]
        if i >= len(samples):
            suffix = random.choice(["", " mensal", " R$", " loja", " 2026", " avulso"])
            out.append(Sample(f"{base.description}{suffix}", base.expected_category, base.transaction_type))
        else:
            out.append(base)
        i += 1
    return out[:n]


# ─────────────────── HTTP helpers ───────────────────


def create_transaction(sample: Sample) -> tuple[Optional[str], float]:
    """POST /api/v1/transactions sem categoryId. Retorna (transaction_id, latencia_ms)."""
    payload = {
        "accountId": ACCOUNT_ID,
        "type": sample.transaction_type,
        "amount": round(random.uniform(10.0, 500.0), 2),
        "description": sample.description,
        "transactionDate": (date.today() - timedelta(days=random.randint(0, 30))).isoformat(),
        "isPaid": True,
    }
    t0 = time.perf_counter()
    try:
        r = SESSION.post(f"{BASE_URL}/api/v1/transactions",
                         data=json.dumps(payload), timeout=15)
    except requests.RequestException as exc:
        print(f"  [warn] falha de rede ao criar transacao: {exc}")
        return None, (time.perf_counter() - t0) * 1000
    latency = (time.perf_counter() - t0) * 1000
    if r.status_code != 201:
        print(f"  [warn] POST /transactions retornou {r.status_code}: {r.text[:120]}")
        return None, latency
    body = r.json()
    tx_id = (body.get("data") or {}).get("id")
    return tx_id, latency


def fetch_classification(tx_id: str) -> tuple[Optional[str], Optional[float], float]:
    """
    GET /api/v1/ai/classifications/transaction/{tx_id} com poll curto.
    Retorna (categoria_predita, confianca, latencia_da_ultima_chamada_ms).
    """
    last_latency = 0.0
    for _attempt in range(POLL_RETRIES):
        t0 = time.perf_counter()
        try:
            r = SESSION.get(
                f"{BASE_URL}/api/v1/ai/classifications/transaction/{tx_id}",
                timeout=10,
            )
        except requests.RequestException:
            time.sleep(POLL_INTERVAL)
            continue
        last_latency = (time.perf_counter() - t0) * 1000
        if r.status_code == 200:
            body = r.json()
            data = body.get("data") or {}
            cat = data.get("suggestedCategoryName")
            conf = data.get("confidenceScore")
            if cat:
                return cat, conf, last_latency
        time.sleep(POLL_INTERVAL)
    return None, None, last_latency


# ─────────────────── Normalizacao de labels ───────────────────

def normalize_label(s: Optional[str]) -> str:
    """
    Comparacao tolerante: descarta diferencas de capitalizacao, acentuacao
    e espacos extras. Ex.: 'Alimentação' == 'alimentacao' == ' Alimentação '.
    Implementa via NFD + filtro de combining chars (Mn).
    """
    if not s:
        return "DESCONHECIDO"
    decomposed = unicodedata.normalize("NFD", s.strip().lower())
    return "".join(ch for ch in decomposed if unicodedata.category(ch) != "Mn")


# ─────────────────── Pipeline ───────────────────

def run():
    corpus = build_corpus(N_SAMPLES)
    print(f"[avaliacao] corpus com {len(corpus)} amostras. Disparando...")

    rows: list[dict] = []
    for idx, sample in enumerate(corpus, start=1):
        tx_id, post_latency = create_transaction(sample)
        if not tx_id:
            rows.append({
                "description": sample.description,
                "expected": sample.expected_category,
                "predicted": None,
                "confidence": None,
                "post_latency_ms": post_latency,
                "classify_latency_ms": None,
                "tx_id": None,
                "failed": True,
            })
            continue

        pred, conf, classify_latency = fetch_classification(tx_id)
        rows.append({
            "description": sample.description,
            "expected": sample.expected_category,
            "predicted": pred,
            "confidence": conf,
            "post_latency_ms": post_latency,
            "classify_latency_ms": classify_latency,
            "tx_id": tx_id,
            "failed": pred is None,
        })

        if idx % 25 == 0:
            print(f"  ...{idx}/{len(corpus)}")

    df = pd.DataFrame(rows)
    df.to_csv("resultados_brutos.csv", index=False)
    print(f"[avaliacao] resultados_brutos.csv gerado ({len(df)} linhas)")

    # Considera apenas amostras com predicao para metricas
    df_eval = df.dropna(subset=["predicted"]).copy()
    if df_eval.empty:
        print("[ERRO] nenhuma classificacao retornou — confira BASE_URL, JWT e se o fyna-ai esta UP.")
        sys.exit(2)

    # Compara de forma tolerante (sem acentos, case-insensitive), mas remapeia
    # de volta para um label canonico "bonito" para tabelas e matriz.
    # Prioridade do label canonico: nome do banco (predicted) > nome do corpus (expected).
    canonical: dict[str, str] = {}
    for raw in df_eval["predicted"].dropna():
        canonical.setdefault(normalize_label(raw), str(raw))
    for raw in df_eval["expected"].dropna():
        canonical.setdefault(normalize_label(raw), str(raw))

    def to_display(raw: Optional[str]) -> str:
        key = normalize_label(raw)
        return canonical.get(key, key)

    y_true = df_eval["expected"].map(to_display)
    y_pred = df_eval["predicted"].map(to_display)

    labels = sorted(set(y_true) | set(y_pred))

    acc = accuracy_score(y_true, y_pred)
    f1_macro = f1_score(y_true, y_pred, average="macro", zero_division=0, labels=labels)
    prec_macro = precision_score(y_true, y_pred, average="macro", zero_division=0, labels=labels)
    rec_macro = recall_score(y_true, y_pred, average="macro", zero_division=0, labels=labels)

    report = classification_report(y_true, y_pred, labels=labels, zero_division=0, digits=4)

    # Metricas por categoria em CSV
    per_class = classification_report(
        y_true, y_pred, labels=labels, zero_division=0, output_dict=True,
    )
    cat_rows = []
    for label in labels:
        stats = per_class.get(label, {})
        cat_rows.append({
            "categoria": label,
            "precision": stats.get("precision", 0.0),
            "recall": stats.get("recall", 0.0),
            "f1_score": stats.get("f1-score", 0.0),
            "support": stats.get("support", 0),
        })
    pd.DataFrame(cat_rows).to_csv("metricas_por_categoria.csv", index=False)

    # Matriz de confusao (normalizada por linha = recall por classe)
    cm = confusion_matrix(y_true, y_pred, labels=labels)
    cm_norm = cm.astype(float)
    row_sums = cm_norm.sum(axis=1, keepdims=True)
    cm_norm = np.divide(cm_norm, row_sums, out=np.zeros_like(cm_norm), where=row_sums != 0)

    fig, ax = plt.subplots(figsize=(max(8, len(labels)), max(6, len(labels) * 0.7)))
    sns.heatmap(cm_norm, annot=True, fmt=".2f", xticklabels=labels, yticklabels=labels,
                cmap="Blues", cbar=True, ax=ax)
    ax.set_xlabel("Predito")
    ax.set_ylabel("Real")
    ax.set_title("Matriz de confusao (normalizada por linha)")
    plt.xticks(rotation=45, ha="right")
    plt.yticks(rotation=0)
    plt.tight_layout()
    plt.savefig("matriz_confusao.png", dpi=150)
    plt.close(fig)

    # Latencias do classificador (apenas amostras com predicao)
    classify_latencies = df_eval["classify_latency_ms"].dropna().astype(float)
    if not classify_latencies.empty:
        p50 = float(np.percentile(classify_latencies, 50))
        p95 = float(np.percentile(classify_latencies, 95))
    else:
        p50 = p95 = float("nan")

    falhas = int(df["failed"].sum())
    relatorio = (
        "===== Relatorio do classificador =====\n"
        f"Total enviado:           {len(df)}\n"
        f"Sem predicao retornada:  {falhas}\n"
        f"Avaliados:               {len(df_eval)}\n\n"
        f"Acuracia global:         {acc:.4f}\n"
        f"F1 (macro):              {f1_macro:.4f}\n"
        f"Precisao (macro):        {prec_macro:.4f}\n"
        f"Revocacao (macro):       {rec_macro:.4f}\n\n"
        f"Latencia p50:            {p50:.1f} ms\n"
        f"Latencia p95:            {p95:.1f} ms\n\n"
        "----- Por categoria -----\n"
        f"{report}\n"
    )
    with open("relatorio_classificador.txt", "w", encoding="utf-8") as fh:
        fh.write(relatorio)

    print(relatorio)
    print("[avaliacao] arquivos gerados:")
    for path in ("resultados_brutos.csv", "metricas_por_categoria.csv",
                 "matriz_confusao.png", "relatorio_classificador.txt"):
        print(f"  - {path}")


if __name__ == "__main__":
    run()

"""
Benchmark de carga H1 — Fyna.

Valida a Hipotese H1: p95 < 200ms para os tres endpoints quentes do backend
Spring sob carga moderada (25 VUs, ~3min).

Endpoints testados:
- POST /api/v1/transactions          (cria uma transacao por iteracao)
- GET  /api/v1/accounts              (lista contas do usuario)
- GET  /api/v1/transactions/{id}     (le uma transacao especifica)

Pre-requisitos (variaveis de ambiente):
- BASE_URL     URL base do backend (ex.: http://localhost:8080)
- JWT_TOKEN    Token JWT valido obtido via /api/v1/auth/login
- ACCOUNT_ID   UUID de uma conta existente do usuario logado
- TX_ID        UUID de uma transacao existente (usado no GET /{id})

Execucao headless (recomendada para coletar CSV):
    locust -f benchmark_carga_h1.py \
           --host $BASE_URL \
           --headless \
           --users 25 --spawn-rate 5 \
           --run-time 3m \
           --csv resultados_h1 --html relatorio_h1.html
"""
import json
import os
import random
import uuid
from datetime import date, timedelta

from locust import HttpUser, between, events, task


def _require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(
            f"Variavel de ambiente {name} nao definida. "
            "Veja docs/benchmarks/README.md para o passo-a-passo."
        )
    return value


@events.test_start.add_listener
def _validate_env(environment, **_kwargs):
    """Falha cedo se faltar config — evita 100% de erros silenciosos."""
    for var in ("JWT_TOKEN", "ACCOUNT_ID", "TX_ID"):
        _require_env(var)


class FynaApiUser(HttpUser):
    """Cada VU autentica via JWT e exercita os tres endpoints do enunciado."""

    # Tempo de pensar curto, para gerar pressao real sem trapacear o p95.
    wait_time = between(0.5, 1.5)

    def on_start(self):
        self.token = _require_env("JWT_TOKEN")
        self.account_id = _require_env("ACCOUNT_ID")
        self.tx_id = _require_env("TX_ID")
        self.client.headers.update({
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        })

    # ───────────────────────── Tarefas ─────────────────────────

    @task(2)
    def create_transaction(self):
        """POST /api/v1/transactions — caminho mais carregado em producao."""
        # categoryId omitido de proposito: assim o backend dispara o classificador
        # async (fire-and-forget) e exercitamos tambem o caminho mais completo.
        payload = {
            "accountId": self.account_id,
            "type": random.choice(["INCOME", "EXPENSE"]),
            "amount": round(random.uniform(5.0, 750.0), 2),
            "description": random.choice([
                "Almoco restaurante",
                "Uber centro",
                "Supermercado semana",
                "Salario mensal",
                "Conta de luz",
                "Mensalidade academia",
                "Cafe padaria",
                "Combustivel posto",
            ]),
            "transactionDate": (
                date.today() - timedelta(days=random.randint(0, 7))
            ).isoformat(),
            "isPaid": True,
        }
        with self.client.post(
            "/api/v1/transactions",
            data=json.dumps(payload),
            name="POST /api/v1/transactions",
            catch_response=True,
        ) as response:
            if response.status_code != 201:
                response.failure(
                    f"esperado 201, recebido {response.status_code}: {response.text[:200]}"
                )

    @task(3)
    def get_accounts(self):
        """GET /api/v1/accounts — endpoint leve, base do dashboard."""
        with self.client.get(
            "/api/v1/accounts",
            name="GET /api/v1/accounts",
            catch_response=True,
        ) as response:
            if response.status_code != 200:
                response.failure(f"status {response.status_code}: {response.text[:200]}")

    @task(2)
    def get_transaction_by_id(self):
        """GET /api/v1/transactions/{id} — leitura indexada por UUID."""
        # Sempre o mesmo TX_ID configurado: garante hit valido sem 404 espurio.
        with self.client.get(
            f"/api/v1/transactions/{self.tx_id}",
            name="GET /api/v1/transactions/{id}",
            catch_response=True,
        ) as response:
            if response.status_code != 200:
                response.failure(f"status {response.status_code}: {response.text[:200]}")

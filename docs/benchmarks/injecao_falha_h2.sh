#!/usr/bin/env bash
# Injecao de falha H2 — Fyna.
#
# Valida a Hipotese H2: taxa de sucesso no backend >= 99% mesmo com o
# microsservico fyna-ai indisponivel, gracas ao desacoplamento via @Async
# + circuit breaker (AIEngineClient).
#
# Roteiro:
#   Fase A (baseline)        — 60s, fyna-ai UP
#   Fase B (falha injetada)  — 120s, fyna-ai DOWN (docker compose stop)
#   Fase C (recuperacao)     — 60s, fyna-ai UP novamente
#
# Em cada fase enviamos POST /api/v1/transactions SEM categoryId, que dispara
# a chamada @Async para o fyna-ai. Se o desacoplamento funcionar, o status
# HTTP do backend continua sendo 201 mesmo na Fase B.
#
# Pre-requisitos (env):
#   BASE_URL     ex.: http://localhost:8080
#   JWT_TOKEN    token JWT valido
#   ACCOUNT_ID   UUID de uma conta existente
#
# Rode na pasta do docker-compose.yml:
#   bash docs/benchmarks/injecao_falha_h2.sh

set -uo pipefail

: "${BASE_URL:?defina BASE_URL=http://localhost:8080}"
: "${JWT_TOKEN:?defina JWT_TOKEN com um token valido}"
: "${ACCOUNT_ID:?defina ACCOUNT_ID com o UUID de uma conta existente}"

# Servico no docker-compose.yml; container_name = fyna-ai-engine
AI_SERVICE="${AI_SERVICE:-fyna-ai}"

# Cadencia das requisicoes (1 RPS por padrao — suficiente para estatistica).
REQ_INTERVAL="${REQ_INTERVAL:-1}"

DURATION_BASELINE="${DURATION_BASELINE:-60}"
DURATION_FAILURE="${DURATION_FAILURE:-120}"
DURATION_RECOVERY="${DURATION_RECOVERY:-60}"

TS="$(date +%Y%m%d_%H%M%S)"
CSV="resultados_h2_${TS}.csv"
SUMMARY="resumo_h2_${TS}.txt"

echo "phase,timestamp,http_status,latency_ms" > "$CSV"

echo "[H2] Iniciando injecao de falha. Logs: $CSV / $SUMMARY"
echo "[H2] Servico alvo no docker compose: $AI_SERVICE"

send_request() {
    local phase="$1"
    local now
    now="$(date +%s%3N)"
    local description="H2 ${phase} ${now}"

    # transactionDate em UTC para evitar surpresa de fuso
    local tx_date
    tx_date="$(date -u +%Y-%m-%d)"

    local body
    body=$(cat <<JSON
{
  "accountId": "${ACCOUNT_ID}",
  "type": "EXPENSE",
  "amount": 10.00,
  "description": "${description}",
  "transactionDate": "${tx_date}",
  "isPaid": true
}
JSON
)

    local start_ns end_ns latency_ms status
    start_ns=$(date +%s%N)
    status=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST "${BASE_URL}/api/v1/transactions" \
        -H "Authorization: Bearer ${JWT_TOKEN}" \
        -H "Content-Type: application/json" \
        --max-time 10 \
        -d "${body}")
    end_ns=$(date +%s%N)
    latency_ms=$(( (end_ns - start_ns) / 1000000 ))

    echo "${phase},${now},${status},${latency_ms}" >> "$CSV"
}

run_phase() {
    local phase="$1"
    local duration="$2"
    local end_at=$(( $(date +%s) + duration ))
    echo "[H2] Fase '${phase}' por ${duration}s..."
    while [ "$(date +%s)" -lt "$end_at" ]; do
        send_request "$phase"
        sleep "$REQ_INTERVAL"
    done
}

# ───────────────────── FASE A: baseline ─────────────────────
run_phase "baseline" "$DURATION_BASELINE"

# ───────────────────── FASE B: falha ───────────────────────
echo "[H2] Parando ${AI_SERVICE}..."
docker compose stop "$AI_SERVICE" >/dev/null
run_phase "failure" "$DURATION_FAILURE"

# ───────────────────── FASE C: recuperacao ─────────────────
echo "[H2] Restaurando ${AI_SERVICE}..."
docker compose start "$AI_SERVICE" >/dev/null
# Da um respiro pro container subir antes de marcar o tempo de recuperacao.
sleep 5
run_phase "recovery" "$DURATION_RECOVERY"

# ───────────────────── Sumario ─────────────────────────────
summarize_phase() {
    local phase="$1"
    awk -F',' -v p="$phase" '
        $1 == p {
            total++
            if ($3 ~ /^2/) success++
            else fail++
        }
        END {
            if (total == 0) {
                printf "  (sem dados para %s)\n", p
                exit
            }
            rate = (success / total) * 100
            printf "  total=%d  sucesso=%d  falha=%d  taxa_sucesso=%.2f%%\n", total, success, fail, rate
        }
    ' "$CSV"
}

veredito_h2() {
    awk -F',' '
        $1 == "failure" {
            total++
            if ($3 ~ /^2/) success++
        }
        END {
            if (total == 0) {
                print "INCONCLUSIVO (sem requisicoes na fase de falha)"
                exit
            }
            rate = (success / total) * 100
            if (rate >= 99.0) printf "APROVADO (>=99%% na fase de falha: %.2f%%)\n", rate
            else              printf "REPROVADO (<99%% na fase de falha: %.2f%%)\n", rate
        }
    ' "$CSV"
}

{
    echo "===== Sumario H2 ====="
    echo "CSV: ${CSV}"
    echo
    echo "[baseline]"
    summarize_phase "baseline"
    echo "[failure]"
    summarize_phase "failure"
    echo "[recovery]"
    summarize_phase "recovery"
    echo
    echo "Veredito H2 (foco em 'failure'): $(veredito_h2)"
} | tee "$SUMMARY"

echo "[H2] Concluido."

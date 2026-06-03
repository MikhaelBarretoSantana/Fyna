"""
Plota a evolucao temporal dos percentis de latencia (p50, p95, p99) do teste H1
a partir do CSV de historico gerado pelo Locust.

Uso:
    python plot_h1_history.py

Saida:
    locust_h1_evolucao.png  na mesma pasta
"""
import csv
import os
import sys

import matplotlib.pyplot as plt

HISTORY_CSV = os.path.join(os.path.dirname(__file__), "resultados_h1_stats_history.csv")
OUT_PNG = os.path.join(os.path.dirname(__file__), "locust_h1_evolucao.png")
LIMIAR_MS = 200


def load_history(path):
    with open(path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = [r for r in reader if r["Name"] == "Aggregated"]
    if not rows:
        sys.exit("Nenhuma linha agregada encontrada no CSV.")

    t0 = int(rows[0]["Timestamp"])
    t  = [int(r["Timestamp"]) - t0 for r in rows]

    def col(name):
        out = []
        for r in rows:
            v = r[name]
            out.append(float(v) if v not in ("", "N/A") else None)
        return out

    return {
        "t":   t,
        "p50": col("50%"),
        "p95": col("95%"),
        "p99": col("99%"),
        "rps": col("Requests/s"),
        "users": [int(r["User Count"]) for r in rows],
    }


def plot(data, out):
    fig, ax = plt.subplots(figsize=(7.2, 3.6))

    ax.plot(data["t"], data["p50"], label="p50", color="#1f77b4", linewidth=1.6)
    ax.plot(data["t"], data["p95"], label="p95", color="#ff7f0e", linewidth=1.6)
    ax.plot(data["t"], data["p99"], label="p99", color="#d62728", linewidth=1.6)

    ax.axhline(LIMIAR_MS, linestyle="--", color="gray", linewidth=1.0,
               label=f"Limiar H1 ({LIMIAR_MS} ms)")

    ax.set_xlabel("Tempo desde inicio do teste (s)")
    ax.set_ylabel("Latencia agregada (ms)")
    ax.set_title("Evolucao dos percentis de latencia sob carga (25 VUs, 3 min)")
    ax.legend(loc="upper right", frameon=True)
    ax.grid(True, alpha=0.3)
    ax.set_ylim(0, 230)

    fig.tight_layout()
    fig.savefig(out, dpi=150)
    print(f"OK: {out}")


if __name__ == "__main__":
    data = load_history(HISTORY_CSV)
    plot(data, OUT_PNG)

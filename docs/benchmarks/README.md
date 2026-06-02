# Kit de Benchmarks Empiricos — Fyna (Rodada 2)

Artefatos para reproduzir os testes que sustentam as Hipoteses H1 e H2 do TCC.

| Arquivo | Finalidade |
|---|---|
| `benchmark_carga_h1.py` | Locust — valida H1 (p95 < 200 ms) em 3 endpoints |
| `injecao_falha_h2.sh` | Injecao de falha — valida H2 (>=99% sucesso) parando `fyna-ai` |
| `avaliacao_classificador.py` | Corpus de 600 transacoes + metricas F1/precisao/revocacao + matriz de confusao |
| `template_secao_empirica.tex` | Template LaTeX da Subsecao 5.5 |

---

## Pre-requisitos

```bash
# Locust (H1)
pip install locust

# Avaliacao do classificador
pip install requests numpy pandas scikit-learn matplotlib seaborn

# Fyna rodando (na raiz do repositorio)
docker compose up -d
docker compose ps   # confirmar fyna-back e fyna-ai
```

---

## Passo 1 — Obter JWT e exportar variaveis

```bash
# Faca login com um usuario que ja tenha pelo menos 1 conta e 1 transacao
curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"seu@email.com","password":"suasenha"}' \
  | python -c "import sys,json; d=json.load(sys.stdin); print(d['data']['accessToken'])"
```

```bash
export BASE_URL=http://localhost:8080
export JWT_TOKEN=<cole o accessToken>
export ACCOUNT_ID=<UUID de uma conta existente>
export TX_ID=<UUID de uma transacao existente>
```

> Resposta de `/auth/login` vem em envelope `ApiResponse`: o token esta em
> `data.accessToken` (nao `accessToken` na raiz).

---

## Passo 2 — H1 (carga)

Rode a partir desta pasta (`docs/benchmarks`):

```bash
locust -f benchmark_carga_h1.py \
       --host $BASE_URL \
       --headless \
       --users 25 --spawn-rate 5 \
       --run-time 3m \
       --csv resultados_h1 --html relatorio_h1.html
```

Saidas:
- `resultados_h1_stats.csv` — percentis por endpoint (coluna `95%` = p95)
- `resultados_h1_history.csv` — serie temporal
- `relatorio_h1.html` — relatorio interativo

Anote no template LaTeX: p50, p95, p99 por endpoint; veredito vs 200 ms.

---

## Passo 3 — H2 (injecao de falha)

> Rodar na **raiz do repositorio** (onde fica `docker-compose.yml`).

```bash
bash docs/benchmarks/injecao_falha_h2.sh
```

O script executa baseline (60 s) -> falha (120 s com `fyna-ai` parado) ->
recuperacao (60 s) e calcula a taxa de sucesso por fase. O backend cria a
transacao mesmo com o `fyna-ai` fora porque a chamada de classificacao e
`@Async` com circuit breaker (`AIEngineClient`).

Saidas: `resultados_h2_<ts>.csv`, `resumo_h2_<ts>.txt`.

Anote no template LaTeX: total por fase, taxa de sucesso na fase de falha,
veredito (>=99%).

---

## Passo 4 — Avaliacao do classificador

```bash
python docs/benchmarks/avaliacao_classificador.py
```

- Gera ~600 transacoes sinteticas (PT-BR) com rotulo verdadeiro.
- Para cada uma chama `POST /api/v1/transactions` sem `categoryId`
  (dispara o classificador) e depois consulta
  `GET /api/v1/ai/classifications/transaction/{id}`.
- Saidas: `resultados_brutos.csv`, `metricas_por_categoria.csv`,
  `matriz_confusao.png`, `relatorio_classificador.txt`.

> Os nomes das categorias canonicas no corpus (`Alimentacao`, `Transporte`,
> ...) precisam existir no banco para o usuario do `JWT_TOKEN`. Ajuste em
> `CORPUS_TEMPLATES` se sua base tem nomes diferentes.

Copie `matriz_confusao.png` para `images/` do projeto LaTeX.

---

## Passo 5 — Preencher o template LaTeX

1. Abra `template_secao_empirica.tex`.
2. Substitua todos os `<PREENCHER: ...>` pelos numeros gerados.
3. Inclua a subsecao no `tcc_mikhael.tex` apos a Subsecao 5.4.
4. Atualize a Subsecao 6.2 para referenciar as tabelas/figura desta secao.
5. Recompile.

---

## Checklist

- [ ] `docker compose ps` mostra `fyna-back` e `fyna-ai` saudaveis
- [ ] `JWT_TOKEN`, `ACCOUNT_ID`, `TX_ID` exportados
- [ ] H1: `resultados_h1_stats.csv` gerado
- [ ] H2: `resumo_h2_*.txt` gerado, fase `failure` >= 99% sucesso
- [ ] Classificador: `matriz_confusao.png` gerada
- [ ] `matriz_confusao.png` copiada para `images/`
- [ ] Template LaTeX preenchido e incluido no `.tex`
- [ ] PDF recompilado e validado

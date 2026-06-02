# Resultados — Rodada 2 (2026-05-27)

Execução completa do kit de benchmarks no usuário `teste` (UUID
`92b097d9-e3a7-4d1e-87da-47204c4043a2`), ambiente local com
`docker compose up -d` (`fyna-backend` e `fyna-ai-engine`).

Use estes números para preencher `template_secao_empirica.tex`.

---

## H1 — Latência (p95 < 200 ms) — APROVADO

Locust 2.44.0, 25 VUs, ramp 5 VUs/s, duração 3 min.
Arquivo: `resultados_h1_stats.csv`.

| Endpoint | p50 (ms) | p95 (ms) | p99 (ms) | Req/s | Erros (%) |
|---|---:|---:|---:|---:|---:|
| POST /api/v1/transactions | 63 | **76** | 85 | 7.07 | 0.00 |
| GET /api/v1/accounts | 15 | **24** | 33 | 10.28 | 0.00 |
| GET /api/v1/transactions/{id} | 17 | **27** | 35 | 6.92 | 0.00 |
| **Agregado** | 18 | **70** | 79 | **24.27** | **0.00** |

- **Total de requisições:** 4347
- **Falhas:** 0 (0.00%)
- **Veredito H1:** APROVADO — p95 agregado **70 ms**, **65% abaixo** do limite de 200 ms. Pior endpoint individual (POST /transactions) também fica em **76 ms < 200 ms**.
- **Comentário:** o endpoint mais lento é o POST de transação (~63 ms p50), o que faz sentido — ele percorre validação, persistência ACID, atualização de saldo, avaliação de anomalia robusta (MAD/Z-robusto em [TransactionService.java:176](../../apps/backend/src/main/java/com/fyna/Fyna/core/features/transactions/domain/service/TransactionService.java#L176)) e gatilho async para a IA. Mesmo com toda essa cadeia o p99 fica em 85 ms.

---

## H2 — Disponibilidade sob falha do `fyna-ai` (≥99%) — APROVADO

Script: `injecao_falha_h2.sh`. Cadência 1 req/s, payload `POST /api/v1/transactions` sem `categoryId` (dispara chamada `@Async` ao classificador).
Arquivos: `resultados_h2_20260527_201101.csv`, `resumo_h2_20260527_201101.txt`.

| Fase | Duração | Total req | Sucesso (2xx) | Taxa (%) |
|---|---:|---:|---:|---:|
| Baseline (IA UP) | 60 s | 43 | 43 | **100.00** |
| **Falha injetada (IA DOWN)** | **120 s** | **87** | **87** | **100.00** |
| Recuperação (IA UP) | 60 s | 42 | 42 | **100.00** |

- **Veredito H2:** APROVADO — **100% de sucesso** durante toda a janela de falha (limite ≥ 99%).
- **Comentário:** valida diretamente o desacoplamento implementado em [AIEngineClient.java:53](../../apps/backend/src/main/java/com/fyna/Fyna/core/features/ai/infrastructure/AIEngineClient.java#L53) — a chamada `classifyTransaction` é `@Async` e a transação é persistida em [TransactionService.java:126](../../apps/backend/src/main/java/com/fyna/Fyna/core/features/transactions/domain/service/TransactionService.java#L126) **antes** do trigger ao classificador. Mesmo com o `fyna-ai-engine` parado, o usuário final não percebe degradação. O circuit breaker (5 falhas / 60 s) começou a abrir após as primeiras tentativas falharem e a partir daí o backend nem chega a tentar a chamada — economizando tempo de timeout.

---

## Avaliação do classificador supervisionado

Script: `avaliacao_classificador.py`, N=300 amostras sintéticas em PT-BR.
Arquivos: `resultados_brutos.csv`, `metricas_por_categoria.csv`, `matriz_confusao.png`, `relatorio_classificador.txt`.

### Métricas globais

| Métrica | Valor |
|---|---:|
| Total enviado | 300 |
| Sem predição retornada | 0 |
| Avaliados | 300 |
| **Acurácia global** | **0.5067** |
| F1 (macro) | 0.3576 |
| Precisão (macro) | 0.4259 |
| Revocação (macro) | 0.3374 |
| **F1 (weighted)** | **0.5490** |
| Latência p50 do classificador | **26.2 ms** |
| Latência p95 do classificador | **36.2 ms** |
| Versão do modelo | (ler de `settings.model_version` no `fyna-ai`) |

> **Nota metodológica:** o F1 *macro* fica artificialmente baixo porque o
> banco do Fyna tem 38 categorias `EXPENSE` + 6 `INCOME` e o corpus só
> cobre 24 delas — as 20 categorias sem suporte entram no cálculo do
> macro com F1=0 e puxam a média. Por isso a leitura mais justa é
> **F1 weighted = 0.549** ou olhar **categoria por categoria**.

### Top-10 categorias por F1

| Categoria | Precision | Recall | F1 | Support |
|---|---:|---:|---:|---:|
| Combustível | 1.000 | 1.000 | **1.000** | 13 |
| Água | 1.000 | 0.800 | **0.889** | 10 |
| Freelance | 0.750 | 1.000 | **0.857** | 9 |
| Livros | 1.000 | 0.700 | **0.824** | 10 |
| Transporte Público | 0.800 | 0.727 | **0.762** | 11 |
| Condomínio | 0.857 | 0.667 | **0.750** | 9 |
| Energia | 1.000 | 0.600 | **0.750** | 10 |
| Internet | 0.692 | 0.818 | **0.750** | 11 |
| Restaurantes | 0.800 | 0.706 | **0.750** | 17 |
| Educação | 0.750 | 0.600 | **0.667** | 10 |

### Categorias problemáticas (Recall baixo)

| Categoria | Precision | Recall | F1 | Support | Observação |
|---|---:|---:|---:|---:|---|
| Farmácia | 0.000 | 0.000 | 0.000 | 13 | descrições vão pra "Saúde" ou "Plano de Saúde" |
| Lazer | 0.000 | 0.000 | 0.000 | 16 | descrições de Netflix/Spotify/Steam pegam "Streaming"/"Jogos" |
| Salário | 0.400 | 0.125 | 0.190 | 16 | confunde com "Outras Receitas" / "Freelance" |
| Saúde | 0.267 | 0.250 | 0.258 | 16 | confunde com "Farmácia" / "Plano de Saúde" |
| Supermercado | 1.000 | 0.211 | 0.348 | 19 | conservador — sobra muita coisa para outras categorias |

### Discussão

- **Pontos fortes:** quando a descrição contém um termo lexicalmente forte
  ligado à categoria (ex.: "Combustível", "Aluguel", "Netflix",
  "Spotify"), o classificador acerta com altíssima precisão. As 10 melhores
  categorias têm F1 ≥ 0.67.
- **Fronteiras semânticas borradas:** o catálogo do Fyna tem categorias
  vizinhas (Farmácia/Saúde/Plano de Saúde; Salário/Freelance/Outras
  Receitas; Streaming/Jogos/Lazer). O classificador, baseado em embeddings
  + similaridade por cosseno
  ([classifier.py:156](../../apps/ai/app/services/classifier.py#L156)),
  tende a colapsar pares próximos.
- **Efeito do aprendizado por correção ausente:** o usuário `teste` tem
  apenas 1 transação confirmada — o classificador não tem histórico
  `was_confirmed=true` para enriquecer a representação de cada
  categoria. O loop de feedback (`AIClassification.was_corrected=true`)
  descrito em [classifier.py:120](../../apps/ai/app/services/classifier.py#L120)
  deve elevar a acurácia em usuários reais ao longo do tempo.
- **Latência:** p50 = 26 ms e p95 = 36 ms incluindo o ciclo POST→async→poll
  do backend. O classificador em si é sub-segundo.

---

## Próximos passos

1. **Preencher** `template_secao_empirica.tex` com os números acima.
2. **Copiar** `matriz_confusao.png` para `images/` do projeto LaTeX.
3. Considerar **rerodar com `N_SAMPLES=600`** se quiser intervalo de confiança mais apertado para o TCC (já que demorou ~8 min para 300, 600 deve caber em ~15 min).
4. Atualizar a **Subseção 6.2** do TCC para referenciar:
   - `\ref{tab:h1-percentis}` na proposição de latência
   - `\ref{tab:h2-disponibilidade}` na proposição de disponibilidade
   - `\ref{tab:classificador-global}` e `\ref{fig:matriz-confusao}` na proposição da IA

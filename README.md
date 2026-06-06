# Fyna

Aplicativo financeiro pessoal com IA — gestão de despesas, receitas, metas, orçamentos
e classificação automática de transações.

## 📦 Estrutura

```
fyna/
├── apps/
│   ├── mobile/      # App Flutter (Android, iOS, Web)
│   ├── backend/     # API Spring Boot (Java 21 + Gradle)
│   └── ai/          # Microserviço de IA (FastAPI + sentence-transformers)
├── docs/            # Documentação e arquivos de exemplo
├── docker-compose.yml
├── .env.example
└── README.md
```

## 🚀 Como rodar

### Pré-requisitos

- Docker Desktop
- PostgreSQL 16 rodando localmente em `localhost:5432`
  (criar database `fyna_db` com usuário `postgres`)
- Flutter SDK (apenas para desenvolvimento mobile)

> Redis 7 sobe via docker-compose como serviço `fyna-redis` — não precisa
> instalar nada na máquina host.

### Setup inicial

1. Clone o repositório:

```bash
git clone https://github.com/MikhaelBarretoSantana/Fyna.git
cd Fyna
```

2. Copie o arquivo de variáveis de ambiente e ajuste os valores:

```bash
cp .env.example .env
# edite .env e troque os valores de senhas/chaves
```

3. Suba os serviços backend (Spring Boot + IA + Redis):

```bash
docker compose up -d --build
```

| Serviço     | Porta | Descrição                                    |
|-------------|-------|----------------------------------------------|
| `fyna-back` | 8080  | API Spring Boot                              |
| `fyna-ai`   | 8081  | Microserviço de IA (FastAPI)                 |
| `fyna-redis`| 6379  | Cache distribuído (categorias)               |
| `fyna-ngrok`| 4040  | Túnel público (UI de inspeção)               |

4. Rode o app Flutter:

```bash
cd apps/mobile
flutter pub get
flutter run
```

## 🔧 Stack

| Camada      | Tecnologia                                              |
|-------------|---------------------------------------------------------|
| Mobile      | Flutter 3.9 (Dart, Dio, fl_chart, local_auth)           |
| Backend     | Spring Boot 4 (Java 21, Gradle, JPA, JWT, Flyway)       |
| IA          | FastAPI + sentence-transformers + scikit-learn          |
| Banco       | PostgreSQL 16                                           |
| Cache       | Redis 7 (Spring Cache, JSON com type wrapper)           |
| Resiliência | Spring Retry (backoff exponencial) + circuit breaker    |
| Auth        | JWT com rotação de refresh token + biometria            |

## 🔑 Features principais

- ✅ Autenticação JWT com refresh token rotation
- ✅ Login por biometria (impressão digital / Face ID)
- ✅ Leitura automática de notificações bancárias (Android)
- ✅ Classificação de transações por IA
- ✅ Predição de gastos e detecção de padrões
- ✅ Orçamentos, metas, transações recorrentes
- ✅ Multi-conta, multi-moeda
- ✅ **Cache distribuído** das categorias do sistema (Redis, TTL 1h)
- ✅ **Resiliência ao microserviço de IA** — retry com backoff exponencial
  (3 tentativas, 500ms→1s→2s) e circuit breaker (abre após 5 falhas, half-open em 60s)
- ✅ **Portabilidade de dados pessoais (LGPD art. 18, V)** via
  `GET /api/v1/users/me/export` — devolve JSON estruturado com perfil,
  preferências, contas, categorias, transações, orçamentos e metas do titular

## 📂 Documentação adicional

- [`docs/docker-compose.prod.example.yml`](docs/docker-compose.prod.example.yml) —
  exemplo de configuração de produção com Redis

## 🤝 Contribuindo

Projeto em desenvolvimento ativo. PRs e issues são bem-vindos.

## 📄 Licença

Proprietário — todos os direitos reservados.

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

3. Suba os serviços backend (Spring Boot + IA):

```bash
docker compose up -d --build
```

A API ficará disponível em `http://localhost:8080`
e a IA em `http://localhost:8081`.

4. Rode o app Flutter:

```bash
cd apps/mobile
flutter pub get
flutter run
```

## 🔧 Stack

| Camada    | Tecnologia                                       |
|-----------|--------------------------------------------------|
| Mobile    | Flutter 3.9 (Dart, Dio, fl_chart, local_auth)    |
| Backend   | Spring Boot 4 (Java 21, Gradle, JPA, JWT, Flyway)|
| IA        | FastAPI + sentence-transformers + scikit-learn   |
| Banco     | PostgreSQL 16                                    |
| Auth      | JWT com rotação de refresh token + biometria     |

## 🔑 Features principais

- ✅ Autenticação JWT com refresh token rotation
- ✅ Login por biometria (impressão digital / Face ID)
- ✅ Leitura automática de notificações bancárias (Android)
- ✅ Classificação de transações por IA
- ✅ Predição de gastos e detecção de padrões
- ✅ Orçamentos, metas, transações recorrentes
- ✅ Multi-conta, multi-moeda

## 📂 Documentação adicional

- [`docs/docker-compose.prod.example.yml`](docs/docker-compose.prod.example.yml) —
  exemplo de configuração de produção com Redis

## 🤝 Contribuindo

Projeto em desenvolvimento ativo. PRs e issues são bem-vindos.

## 📄 Licença

Proprietário — todos os direitos reservados.

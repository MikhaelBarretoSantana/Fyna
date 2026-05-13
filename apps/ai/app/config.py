"""
FYNA AI Microservice — Configuration.
Reads from environment variables with sensible defaults.
"""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="FYNA_AI_")

    database_url: str = "postgresql://postgres:postgres@localhost:5432/fyna_db"
    classifier_model: str = "paraphrase-multilingual-MiniLM-L12-v2"
    classifier_confidence_threshold: float = 0.35
    prediction_months_history: int = 6
    prediction_confidence_level: float = 0.95
    pattern_min_significance: float = 0.3
    pattern_anomaly_z_threshold: float = 2.5
    model_version: str = "fyna-ai-v1.0"
    service_name: str = "fyna-ai-engine"
    debug: bool = False

    # Chave interna usada pelo Spring Boot para autenticar chamadas ao microserviço.
    # Definir via variável de ambiente: FYNA_AI_INTERNAL_API_KEY=<valor seguro>
    # Em produção NUNCA usar o valor padrão.
    internal_api_key: str = "dev-insecure-key-change-in-prod"


settings = Settings()

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://smieciarka:smieciarka@localhost:5432/smieciarka"

    jwt_secret: str = "change-me-dev-only"
    jwt_access_ttl: int = 900
    jwt_refresh_ttl: int = 2592000

    otp_mock: bool = True

    embedding_provider: str = "fastembed"
    embedding_model: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    embedding_dim: int = 384
    llm_api_key: str = ""

    match_threshold_low: float = 0.55
    match_threshold_high: float = 0.75

    listing_ttl_hours: int = 72


settings = Settings()

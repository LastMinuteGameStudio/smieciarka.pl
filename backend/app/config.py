from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+asyncpg://smieciarka:smieciarka@localhost:5432/smieciarka"

    jwt_secret: str = "change-me-dev-only"
    jwt_access_ttl: int = 900
    jwt_refresh_ttl: int = 2592000

    otp_mock: bool = True

    # "jina" (hosted, 1024-dim) or "fastembed" (local offline fallback, 384-dim).
    # Changing this changes the vector dimension: migrate and reindex.
    embedding_provider: str = "jina"
    embedding_model: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    embedding_dim: int = 1024
    jina_api_key: str = ""
    gemini_api_key: str = ""
    # Pinned-but-overridable: Google retires model ids for new keys without
    # notice (gemini-2.5-flash already 404s), and the -latest aliases shift.
    gemini_model: str = "gemini-flash-lite-latest"
    llm_api_key: str = ""

    # Cosine prefilter only: bounds how many rerank calls a new listing costs,
    # never decides a match. Must stay loose -- jina-v3 cosine scores sit low
    # (true positives bottomed at 0.053 on the eval set), so a tight value here
    # silently drops real matches before the reranker sees them. The LIMIT, not
    # the threshold, is the real bound. Retune both if the model changes.
    match_candidate_threshold: float = 0.0
    match_candidate_limit: int = 100

    # The actual match decision, applied to calibrated reranker scores.
    # 0.10 sits in the measured gap (false positives topped out at 0.086,
    # true positives bottomed at 0.111) on the eval set in tests/matching_eval.
    match_rerank_threshold: float = 0.10

    match_threshold_low: float = 0.55
    match_threshold_high: float = 0.75

    listing_ttl_hours: int = 72
    max_filters_per_user: int = 10


settings = Settings()

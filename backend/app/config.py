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

    # --- Images ---
    # s3_endpoint is reachable from the API; s3_public_endpoint is the host a
    # client will call. They differ under compose (minio:9000 vs
    # localhost:9000) and SigV4 signs the Host header, so a presigned URL has
    # to be produced by a client bound to the public one.
    s3_endpoint: str = "http://localhost:9000"
    s3_public_endpoint: str = ""
    s3_bucket: str = "listing-images"
    s3_access_key: str = "smieciarka"
    s3_secret_key: str = "smieciarka-dev-only"
    s3_region: str = "us-east-1"
    s3_presign_ttl: int = 3600

    max_images_per_listing: int = 6
    max_image_bytes: int = 10 * 1024 * 1024
    thumb_max_px: int = 480
    image_max_px: int = 1600

    # Captioning reuses GEMINI_API_KEY. Off means uploads still work, the
    # listing just keeps the caption it already had (usually none).
    vision_enabled: bool = True
    gemini_vision_model: str = "gemini-flash-lite-latest"

    @property
    def s3_signing_endpoint(self) -> str:
        """Endpoint a presigned URL is signed for; falls back to the internal one."""
        return self.s3_public_endpoint or self.s3_endpoint


settings = Settings()

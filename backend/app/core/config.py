from pydantic_settings import BaseSettings, SettingsConfigDict


# ---------------- Settings ----------------
# Pydantic settings pulls from environment variables automatically, so the
# same code runs in Docker, CI, and production without code changes -- only
# the .env / environment differs.
class Settings(BaseSettings):
    ENVIRONMENT: str = "development"

    # Backend <-> ML service communication.
    # The ML service is a separate container, so the backend never imports
    # ML code directly -- it calls this over HTTP, same as an external client would.
    ML_SERVICE_URL: str = "http://ml:8500"

    # Database (placeholder until we decide Postgres vs. something else for
    # storing member/committee/prediction records).
    DATABASE_URL: str = "postgresql://daira:daira@db:5432/daira"

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()

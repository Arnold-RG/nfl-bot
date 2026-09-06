"""Application settings for the NFL BOT modular monolith."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "NFL BOT API"
    app_version: str = "0.1.0"
    environment: str = "development"
    api_prefix: str = ""

    # Local Flutter web (8080) + Creator SOC (9090) + common localhost variants
    cors_origins: str = (
        "http://localhost:8080,"
        "http://127.0.0.1:8080,"
        "http://localhost:9090,"
        "http://127.0.0.1:9090,"
        "http://localhost:3000"
    )

    member_app_url: str = "http://localhost:8080"
    creator_soc_url: str = "http://localhost:9090"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()

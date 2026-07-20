"""Application configuration loaded from the environment."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime settings, read once from the environment."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = (
        "postgresql+psycopg://postgres:password@localhost:5432/workspace"
    )


@lru_cache
def get_settings() -> Settings:
    """Return the process-wide settings, cached after first load."""
    return Settings()

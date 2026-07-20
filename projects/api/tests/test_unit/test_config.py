"""Tests for application settings."""

from api.config import Settings, get_settings


def test_default_database_url_uses_async_psycopg_driver() -> None:
    """The default DSN targets psycopg3's async driver."""
    settings = Settings()
    assert settings.database_url.startswith("postgresql+psycopg://")


def test_database_url_is_read_from_environment(monkeypatch) -> None:
    """DATABASE_URL overrides the default and is cached per process."""
    get_settings.cache_clear()
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u:p@db:5432/other")
    try:
        assert get_settings().database_url.endswith("@db:5432/other")
    finally:
        get_settings.cache_clear()

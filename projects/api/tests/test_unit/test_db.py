"""Tests for the async database engine factory."""

from sqlalchemy.ext.asyncio import AsyncEngine

from api.db import create_engine


def test_create_engine_returns_async_engine_with_psycopg_driver() -> None:
    """The engine is async and bound to the psycopg3 driver."""
    engine = create_engine("postgresql+psycopg://u:p@localhost:5432/workspace")
    assert isinstance(engine, AsyncEngine)
    assert engine.url.drivername == "postgresql+psycopg"

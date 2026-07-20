"""Async SQLAlchemy engine and session management."""

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from api.config import get_settings


def create_engine(database_url: str) -> AsyncEngine:
    """Build an async engine bound to the psycopg3 driver."""
    return create_async_engine(database_url, pool_pre_ping=True)


engine = create_engine(get_settings().database_url)
session_factory = async_sessionmaker(engine, expire_on_commit=False)


async def get_session() -> AsyncIterator[AsyncSession]:
    """Yield a session scoped to a single request."""
    async with session_factory() as session:
        yield session

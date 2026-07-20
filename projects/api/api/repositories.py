"""Data-access adapters over the async session."""

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class HealthRepository:
    """Connectivity checks against the database."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def ping(self) -> bool:
        """Run a trivial query to confirm the database answers."""
        await self._session.execute(text("SELECT 1"))
        return True

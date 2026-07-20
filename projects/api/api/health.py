"""Health check endpoints."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from api.db import get_session
from api.repositories import HealthRepository

router = APIRouter()


class HealthStatus(BaseModel):
    """Liveness state of the service."""

    status: str


class ReadinessStatus(BaseModel):
    """Readiness state, including database connectivity."""

    status: str
    database: str


def get_health_repository(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> HealthRepository:
    """Provide a repository bound to the request-scoped session."""
    return HealthRepository(session)


@router.get("/health")
def get_health() -> HealthStatus:
    """Report that the service is reachable."""
    return HealthStatus(status="ok")


@router.get("/health/ready")
async def get_readiness(
    repo: Annotated[HealthRepository, Depends(get_health_repository)],
) -> ReadinessStatus:
    """Report readiness, failing with 503 when the database is unreachable."""
    try:
        await repo.ping()
    except SQLAlchemyError as exc:
        raise HTTPException(status_code=503, detail="database unavailable") from exc
    return ReadinessStatus(status="ok", database="ok")

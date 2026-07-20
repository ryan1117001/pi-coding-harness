"""Service status endpoint."""

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class ServiceStatus(BaseModel):
    """Identifying metadata for the running service."""

    service: str
    version: str


@router.get("/status")
def get_status() -> ServiceStatus:
    """Report the service name and version."""
    return ServiceStatus(service="api", version="1.0.0")

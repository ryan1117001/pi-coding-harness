"""Tests for the database-backed readiness probe."""

from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError

from api.health import get_health_repository
from api.main import create_app


class _StubRepository:
    def __init__(self, *, reachable: bool) -> None:
        self._reachable = reachable

    async def ping(self) -> bool:
        if not self._reachable:
            raise OperationalError("SELECT 1", {}, Exception("down"))
        return True


def _client_with_repo(*, reachable: bool) -> TestClient:
    app = create_app()
    app.dependency_overrides[get_health_repository] = lambda: _StubRepository(
        reachable=reachable
    )
    return TestClient(app)


def test_readiness_reports_ok_when_database_reachable() -> None:
    client = _client_with_repo(reachable=True)
    response = client.get("/api/v1/health/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "ok"}


def test_readiness_returns_503_when_database_unreachable() -> None:
    client = _client_with_repo(reachable=False)
    response = client.get("/api/v1/health/ready")
    assert response.status_code == 503

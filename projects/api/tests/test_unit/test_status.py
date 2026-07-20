"""Tests for the versioned status endpoint."""

from fastapi.testclient import TestClient


def test_status_returns_service_metadata(client: TestClient) -> None:
    """The versioned status endpoint reports service metadata."""
    response = client.get("/api/v1/status")

    assert response.status_code == 200
    body = response.json()
    assert body["service"] == "api"
    assert body["version"] == "1.0.0"

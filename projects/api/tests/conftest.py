"""Unit tests configuration module."""

import pytest
from fastapi.testclient import TestClient

from api.main import create_app


@pytest.fixture
def client() -> TestClient:
    """Provide a TestClient bound to a fresh application instance."""
    return TestClient(create_app())

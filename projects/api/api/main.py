"""Application factory and entrypoint."""

from fastapi import FastAPI

from api import health

API_V1_PREFIX = "/api/v1"


def create_app() -> FastAPI:
    """Build a FastAPI application with all routers mounted."""
    app = FastAPI(title="api", version="1.0.0")
    app.include_router(health.router, prefix=API_V1_PREFIX)
    return app


app = create_app()

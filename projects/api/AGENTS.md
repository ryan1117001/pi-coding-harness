# API project instructions

FastAPI service on Python 3.14, managed with uv. Persistence uses async SQLAlchemy and psycopg3 against the `postgres` project.

## Layout and boundaries

- `api/main.py` owns `create_app` and the uvicorn `app` instance.
- `api/config.py` reads typed `pydantic-settings` configuration once at module boundaries.
- `api/db.py` owns the async engine, session factory, and `get_session` dependency.
- Put data access behind typed repository adapters in `api/repositories.py`; return models or typed values, never raw rows.
- Keep one router per resource and mount it under `API_V1_PREFIX` in `create_app`.
- Use FastAPI dependencies instead of handler-level global state.
- Handlers return Pydantic models. Raise `HTTPException` with explicit status codes rather than returning error dictionaries.

## Python and tests

- Type every function signature and Pydantic/dataclass field.
- Use f-strings; do not use `%` formatting or `.format()`.
- Ruff owns linting and formatting; do not hand-format around it.
- Follow RED, GREEN, REFACTOR. Unit tests live in `tests/test_unit/`, use deterministic fixtures, and replace repositories through `dependency_overrides`.
- Mock outbound HTTP and other external systems at their boundary. Use the `python-testing-patterns` skill for non-trivial fixture or async-test design.
- `nx test api` runs pytest and enforces 85% coverage.

## Database and containers

- `DATABASE_URL` defaults to `postgresql+psycopg://postgres:password@localhost:5432/workspace` outside Compose; Compose uses `postgres` as the host.
- Keep the psycopg3 async URL scheme (`postgresql+psycopg://`).
- The multi-stage `Dockerfile` produces a non-root Python 3.14 slim runtime image serving uvicorn on port 8000.
- Add runtime dependencies with `pnpm exec nx run api:add --name=<pkg>` and development dependencies with `--dev` so `pyproject.toml` and `uv.lock` stay synchronized.

Operational commands live in [`README.md`](README.md). Run them from the repository root.

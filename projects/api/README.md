# api

FastAPI service on Python 3.14, managed with [uv](https://docs.astral.sh/uv/).
Persistence is PostgreSQL via async SQLAlchemy + psycopg3 (the
[`postgres`](../postgres/) image). Scaffolded with `@nxlv/python:uv-project`;
linting and formatting via ruff, tests via pytest.

See [`AGENTS.md`](AGENTS.md) for file boundaries, Python conventions, tests, database access, and commands.

## Routes

Every router mounts under `/api/v1` (`API_V1_PREFIX`):

- `GET /api/v1/health` — liveness.
- `GET /api/v1/health/ready` — readiness; probes Postgres and returns 503 if unreachable.
- `GET /api/v1/status` — service status.

## Quick start

Run the commands below from the repository root. Compose supplies the database host `postgres`; the API's non-Compose default uses `localhost`.

```bash
docker compose up -d postgres     # from the repo root — the DB the api talks to
pnpm exec nx serve api            # uvicorn with --reload on http://localhost:8000
```

## Commands

```bash
pnpm exec nx test api             # pytest with coverage (fails under 85%)
pnpm exec nx lint api             # ruff check
pnpm exec nx format api           # ruff format --check
pnpm exec nx build api            # wheel into projects/api/dist
```

Add dependencies with `pnpm exec nx run api:add --name=<pkg>` (`--dev` for dev deps)
so `pyproject.toml` and `uv.lock` stay in sync.

## Configuration

`DATABASE_URL` (default `postgresql+psycopg://postgres:password@localhost:5432/workspace`)
selects the database; the driver must be the psycopg3 async one (`postgresql+psycopg://`).
See [`docs/references/environment-variables.md`](../../docs/references/environment-variables.md).

## Docker

A multi-stage [`Dockerfile`](Dockerfile) (Python 3.14 slim + uv) builds a non-root
runtime image serving uvicorn on port 8000:

```bash
docker compose up --build api     # runs api + postgres; DATABASE_URL targets the postgres service after its health check
```

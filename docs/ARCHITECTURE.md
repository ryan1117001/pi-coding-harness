# Architecture

## Workspace

Nx monorepo managed with pnpm. Projects live under `projects/` and are scaffolded with Nx generators; never hand-write a new `project.json`. See [`references/nx-guidelines.md`](references/nx-guidelines.md). Tooling includes Biome, Vitest, Playwright, Storybook, and `@nxlv/python` with uv. Pi project configuration lives under [`.pi/`](../.pi/), Agent Skills under [`.agents/skills/`](../.agents/skills/), and workspace policy in [`AGENTS.md`](../AGENTS.md).

## Projects

| Project | Type | Stack | Notes |
| --------- | ------ | ------- | ------- |
| [`web`](../projects/web/) | React SPA | React 19, Vite 8, Tailwind v4, daisyUI v5, TanStack Router, TanStack Query, Paraglide JS | English messages compile from `projects/web/messages/`. See [`projects/web/AGENTS.md`](../projects/web/AGENTS.md). |
| [`web-e2e`](../projects/web-e2e/) | Playwright e2e | Playwright | See [`projects/web-e2e/AGENTS.md`](../projects/web-e2e/AGENTS.md). |
| [`api`](../projects/api/) | FastAPI service | Python 3.14, uv, FastAPI, uvicorn, pytest, Ruff, async SQLAlchemy, psycopg3 | See [`projects/api/AGENTS.md`](../projects/api/AGENTS.md). |
| [`postgres`](../projects/postgres/) | Infrastructure image | PostgreSQL 18, pgvector, Apache AGE | See [`projects/postgres/AGENTS.md`](../projects/postgres/AGENTS.md). |

## Service topology

| From | To | Protocol | Notes |
|------|----|----------|-------|
| `api` | `postgres` | PostgreSQL wire (async SQLAlchemy + psycopg3) | DSN from `DATABASE_URL` (default `postgresql+psycopg://postgres:password@localhost:5432/workspace`; in Compose the host is the `postgres` service). `GET /api/v1/health/ready` probes the connection. Both run as containers via [`compose.yml`](../compose.yml). |

`web` is a standalone SPA with no backend. When a service starts talking to another
over the network (HTTP client, DB, external API), record the connection here.

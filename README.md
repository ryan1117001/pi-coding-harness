# workspace

**workspace** is an Nx monorepo with a reproducible Pi coding-agent harness. It includes Nx, pnpm, Biome, Vitest, Playwright, Storybook, `@nxlv/python` with uv, project instructions, Agent Skills, delegated agents, planning, diagnostics, web access, and lazy MCP integration.

Read [`AGENTS.md`](AGENTS.md) for workspace policy, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the repository map, and [`docs/pi-harness/`](docs/pi-harness/) for Pi setup and extension provenance.

## Use this template

1. Create a repository from the template and clone it.
2. Run `pnpm install`.
3. Install Pi 0.80.10 or a compatible newer release and start `pi` at the repository root.
4. Review and accept Pi's project-trust prompt. Pi installs the exact package versions from [`.pi/settings.json`](.pi/settings.json) into ignored `.pi/npm/`.
5. Update the project name in [`package.json`](package.json) and this heading.

## Quick start

```bash
pnpm install
pnpm exec playwright install
pnpm exec nx run-many -t lint test
pnpm exec nx graph
pi
```

Scaffold projects with Nx generators, never by hand-writing `project.json`. See [`docs/references/nx-guidelines.md`](docs/references/nx-guidelines.md) and use the `nx-generate` skill.

## Layout

| Path | Purpose |
| --- | --- |
| [`projects/web/`](projects/web/) | React 19 + Vite 8 SPA with Tailwind v4, daisyUI v5, TanStack Router, and TanStack Query. |
| [`projects/web-e2e/`](projects/web-e2e/) | Playwright end-to-end tests for `web`. |
| [`projects/api/`](projects/api/) | FastAPI service with Python 3.14, uv, pytest, Ruff, async SQLAlchemy, and psycopg3. |
| [`projects/postgres/`](projects/postgres/) | PostgreSQL 18 image with pgvector and Apache AGE. |
| [`docs/`](docs/) | Architecture, design decisions, standards, references, approved plans, and Pi harness documentation. |
| [`.pi/`](.pi/) | Tracked Pi settings, planning profile, project agents, and prompt templates; runtime packages are ignored. |
| [`.agents/skills/`](.agents/skills/) | Project and vendored Agent Skills, with upstream provenance in [`skills-lock.json`](skills-lock.json). |
| [`AGENTS.md`](AGENTS.md) | Workspace policy loaded by Pi; each project has a narrower `AGENTS.md`. |
| [`tools/`](tools/) | Workspace-level scripts. |

## Documentation

- [`CONTRIBUTING.md`](CONTRIBUTING.md) — setup, workflow, checks, and project scaffolding.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — projects, tooling, and service topology.
- [`docs/pi-harness/`](docs/pi-harness/) — Pi trust, packages, skills, agents, and workflows.

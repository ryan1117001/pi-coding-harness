# workspace

**workspace** is an Nx monorepo with a Pi coding-agent harness. It includes Nx, pnpm, Biome, Vitest, Playwright, Storybook, `@nxlv/python` with uv, project instructions, Agent Skills, delegated agents, planning, diagnostics, web access, and lazy MCP integration.

Read [`AGENTS.md`](./AGENTS.md) for workspace policy, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the repository map, and [`docs/coding-agent-harness/`](docs/coding-agent-harness/) for Pi setup and extension provenance.

## Use this template

1. Create a repository from the template and clone it.
2. Run `pnpm install`.
3. Install a compatible Pi release and start `pi` at the repository root.
4. Review and accept Pi's project-trust prompt. Pi installs the configured project packages from [`.pi/settings.json`](.pi/settings.json) into ignored `.pi/npm/`.
5. Update the project name in [`package.json`](package.json) and this heading.

## Quick start

```bash
pnpm install
pnpm exec playwright install chromium  # web unit and Storybook browser tests
pnpm exec nx run-many -t lint test
pnpm exec nx graph
pi
```

Run `pnpm exec playwright install` instead when executing the cross-browser [`web-e2e`](projects/web-e2e/README.md) suite. To start the local service stack, optionally copy `.env.example` to `.env`, then run `docker compose up --build`; see [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Dev Container quick start

The Dev Container is an optional development path; host development remains supported. With Docker available to VS Code, open this repository and select **Dev Containers: Reopen in Container**. For the pinned headless workflow, cache reset, credentials, browser scope, and teardown, see [`.devcontainer/README.md`](.devcontainer/README.md).

Start it and open an interactive terminal without VS Code:

```bash
pnpm exec devcontainer up --workspace-folder . --frozen-lockfile
pnpm exec devcontainer exec --workspace-folder . bash -l
```

Run `pi` inside that shell, or see [the terminal and Pi workflow](.devcontainer/README.md#interactive-terminal-and-pi) for direct launch and user-level extension opt-in commands.

Scaffold projects with Nx generators, never by hand-writing `project.json`. See [`docs/references/nx-guidelines.md`](docs/references/nx-guidelines.md) and use the `nx-generate` skill.

## Layout

| Path | Purpose |
| --- | --- |
| [`projects/web/`](projects/web/) | React 19 + Vite 8 SPA with Tailwind v4, daisyUI v5, TanStack Router, and TanStack Query. |
| [`projects/web-e2e/`](projects/web-e2e/) | Playwright end-to-end tests for `web`. |
| [`projects/api/`](projects/api/) | FastAPI service with Python 3.14, uv, pytest, Ruff, async SQLAlchemy, and psycopg3. |
| [`projects/postgres/`](projects/postgres/) | PostgreSQL 18 image with pgvector and Apache AGE. |
| [`docs/`](docs/) | Architecture, design decisions, standards, references, approved plans, and coding-agent-harness documentation. |
| [`.pi/`](.pi/) | Tracked Pi settings, planning profile, project agents, and prompt templates; runtime packages are ignored. |
| [`.agents/skills/`](.agents/skills/) | Project and vendored Agent Skills, with upstream provenance in [`skills-lock.json`](skills-lock.json). |
| [`AGENTS.md`](./AGENTS.md) | Workspace policy loaded by Pi; each project has a narrower `AGENTS.md`. |
| [`tools/`](tools/) | Workspace-level scripts. |

## Documentation

| Need | Read |
| --- | --- |
| Set up, contribute, and run checks | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Understand projects, containers, workspace topology, and service connections | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| Find references, plans, decisions, and standards | [`docs/`](docs/) |
| Configure Pi, skills, agents, and workflows | [`docs/coding-agent-harness/`](docs/coding-agent-harness/) |
| Follow mandatory agent policy | [`AGENTS.md`](./AGENTS.md) |

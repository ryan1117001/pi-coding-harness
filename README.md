# workspace

**workspace** is an Nx monorepo with a Pi coding-agent harness. It includes Nx, pnpm, Biome, Vitest, Playwright, Storybook, `@nxlv/python` with uv, project instructions, Agent Skills, delegated agents, planning, diagnostics, web access, and lazy MCP integration.

Read [`AGENTS.md`](./AGENTS.md) for workspace policy, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the repository map, and [`docs/coding-agent-harness/`](docs/coding-agent-harness/) for Pi setup and extension provenance.

## Use this template

1. Create a repository from the template and clone it.
2. Run `pnpm install`.
3. Install a compatible Pi release and start `pi` at the repository root.
4. Review and accept Pi's project-trust prompt. Pi installs the configured project packages from [`.pi/settings.json`](.pi/settings.json) into ignored `.pi/npm/`.
5. Update the project name in [`package.json`](package.json) and this heading. The name `workspace` is the intentional generic container identity used by the Compose project, the Dev Container, `POSTGRES_DB`, and the named volumes; leave it alone unless you also rename all of them together.

## Quick start

```bash
pnpm install
pnpm exec playwright install chromium
pnpm exec nx run-many -t lint typecheck test build --parallel=3
pnpm docs:check
pi
```

Install all Playwright browsers before running the cross-browser [`web-e2e`](projects/web-e2e/README.md) suite. For service startup and contribution checks, use [`CONTRIBUTING.md`](CONTRIBUTING.md). This template ships no CI workflows; run the quality gates locally or add the workflows your fork needs.

## Dev Container quick start

The Dev Container is an optional development path; host development remains supported. With Docker available to VS Code, open this repository and select **Dev Containers: Reopen in Container**. For the pinned headless workflow, cache reset, credentials, browser scope, and teardown, see [`.devcontainer/README.md`](.devcontainer/README.md).

Start it and open an interactive terminal without VS Code:

```bash
pnpm exec devcontainer up --workspace-folder . --frozen-lockfile
pnpm exec devcontainer exec --workspace-folder . bash -l
```

Run `pi` inside that shell, or see [the terminal and Pi workflow](.devcontainer/README.md#interactive-terminal-and-pi) for direct launch and user-level extension opt-in commands.

## Docker Sandbox Pi runtime

[Docker Sandboxes](docs/references/docker-sandbox-pi.md) is a separate, manual optional Pi runtime. It does not replace host development or the trusted Dev Container. It requires `sbx` 0.38.0 or newer and defaults to a validated standalone clone of committed `HEAD` rather than the ordinary checkout. Read the [operational reference](docs/references/docker-sandbox-pi.md) before use.

Scaffold projects with Nx generators, never by hand-writing `project.json`. See [`docs/references/nx-guidelines.md`](docs/references/nx-guidelines.md) and use the `nx-generate` skill.

## Layout

| Path                                       | Purpose                                                                                                        |
| ------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| [`projects/web/`](projects/web/)           | React 19 + Vite 8 SPA with Tailwind v4, daisyUI v5, TanStack Router, and TanStack Query.                       |
| [`projects/web-e2e/`](projects/web-e2e/)   | Playwright end-to-end tests for `web`.                                                                         |
| [`projects/api/`](projects/api/)           | FastAPI service with Python 3.14, uv, pytest, Ruff, async SQLAlchemy, and psycopg3.                            |
| [`projects/postgres/`](projects/postgres/) | PostgreSQL 18 image with pgvector and Apache AGE.                                                              |
| [`docs/`](docs/)                           | Architecture, design decisions, standards, references, approved plans, and coding-agent-harness documentation. |
| [`.pi/`](.pi/)                             | Tracked Pi settings, planning profile, project agents, and prompt templates; runtime packages are ignored.     |
| [`.agents/skills/`](.agents/skills/)       | Project and vendored Agent Skills, with upstream provenance in [`skills-lock.json`](skills-lock.json).         |
| [`AGENTS.md`](./AGENTS.md)                 | Workspace policy loaded by Pi; each project has a narrower `AGENTS.md`.                                        |
| [`.devcontainer/`](.devcontainer/)         | Optional trusted Dev Container: image, Compose layers, setup, and smoke/contract tests.                       |
| [`.sandbox/`](.sandbox/)                   | Optional Docker Sandbox Pi runtime: launcher, in-VM bootstrap, and its synthetic and live tests.              |
| [`tools/`](tools/)                         | Workspace-level scripts, the shared shell library, and [`toolchain.env`](tools/toolchain.env) version pins.   |

## Documentation

| Need                                                                         | Read                                                       |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Set up, contribute, and run checks                                           | [`CONTRIBUTING.md`](CONTRIBUTING.md)                       |
| Understand projects, containers, workspace topology, and service connections | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)             |
| Find references, plans, decisions, and standards                             | [`docs/`](docs/)                                           |
| Configure Pi, skills, agents, and workflows                                  | [`docs/coding-agent-harness/`](docs/coding-agent-harness/) |
| Follow mandatory agent policy                                                | [`AGENTS.md`](./AGENTS.md)                                 |

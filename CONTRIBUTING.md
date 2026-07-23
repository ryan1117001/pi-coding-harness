# Contributing

This Nx monorepo uses pnpm. Read [`AGENTS.md`](AGENTS.md), the nearest project `AGENTS.md`, and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) before changing a project.

## Setup

```bash
pnpm install
pnpm exec playwright install
cp .env.example .env             # optional for Compose and api
pi
```

Review and accept Pi's project-trust prompt. It installs the pinned project packages from `.pi/settings.json` into ignored `.pi/npm/`. See [`docs/coding-agent-harness/`](docs/coding-agent-harness/) for setup and provenance.

The `api` and `postgres` projects run through root Docker Compose. Environment variables are documented in [`docs/references/environment-variables.md`](docs/references/environment-variables.md).

## Workflow

- Follow RED, GREEN, REFACTOR for features, bug fixes, and behavior changes. State when an allowed generated-code, prototype, config, documentation, or formatting exception applies. Use the `test-driven-development` skill for the full mechanics.
- Update documentation in the same change when behavior, APIs, configuration, architecture, or developer workflow changes.
- Follow the nearest project `AGENTS.md` for stack-specific boundaries, tests, and commands.
- Use Conventional Commits (`feat:`, `fix:`, `chore:`, and related types), enforced through [`.cz.toml`](.cz.toml).
- Use Plannotator for non-trivial plans. The plan is authored directly under `docs/prompts/` and registered after approval without making a copy.

## Checks before pushing

The pre-commit configuration runs fix and test targets. Run affected checks before opening a pull request:

```bash
pnpm exec nx affected -t lint test --base=origin/main --parallel=3
```

Also run focused project tests during development and Lens diagnostics for edited source.

## Adding a project

Never hand-write a new `project.json`. Use an Nx generator with `--dry-run` first; see [`docs/references/nx-guidelines.md`](docs/references/nx-guidelines.md).

1. Generate under `projects/` and verify with `pnpm exec nx show project <name> --json`.
2. Provide consistent source-project targets: `lint`, `lint:fix`, `format`, `format:fix`, and `test`, plus `serve`/`build` where applicable.
3. Add `projects/<name>/README.md` and `projects/<name>/AGENTS.md`.
4. Update the root layout table and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
5. Write a design document before introducing a new cross-service connection, then record the resulting topology in the architecture document.

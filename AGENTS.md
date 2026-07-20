# Workspace agent policy

## Scope

- Read the nearest project `AGENTS.md` before changing files under `projects/`; project instructions refine this file.
- Use [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the repository map and service topology.
- Use [`docs/standards/documentation.md`](docs/standards/documentation.md) for documentation conventions.

| Area | Instructions |
| --- | --- |
| Web SPA | [`projects/web/AGENTS.md`](projects/web/AGENTS.md) |
| Web end-to-end tests | [`projects/web-e2e/AGENTS.md`](projects/web-e2e/AGENTS.md) |
| FastAPI service | [`projects/api/AGENTS.md`](projects/api/AGENTS.md) |
| PostgreSQL image | [`projects/postgres/AGENTS.md`](projects/postgres/AGENTS.md) |

## Change policy

- Use test-driven development for features, bug fixes, and behavior changes: RED, GREEN, REFACTOR. Confirm the failing test fails for the intended reason. Exceptions are generated code, sandbox prototypes, and config-, documentation-, or formatting-only changes; state the exception.
- Update documentation in the same change when behavior, APIs, configuration, architecture, or developer workflow changes.
- Keep browser code behind its own backend boundary. Record every new network dependency or service connection in `docs/ARCHITECTURE.md`; write a design document first when the connection changes architecture.
- Keep edits narrow. Do not add dependencies, infrastructure, or speculative abstractions without an approved requirement.

## Planning and review

- Use Plannotator for non-trivial plans. Start the working plan directly at `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md`; after approval, use `save-approved-plan` to validate and register that same file before implementation. Never copy or rewrite the approved plan.
- Use the builtin reviewer for code review; its project override loads the `codebase-analysis` skill. Use the project `technical-writer` for substantial documentation work.

## Nx workflow

- Use Nx generators, with `--dry-run` first, for projects and generated workspace structure. Never hand-write a new `project.json`.
- Give source projects consistent `lint`, `lint:fix`, `format`, `format:fix`, and `test` targets plus `serve`/`build` where applicable. Verify with `pnpm exec nx show project <name> --json`.
- Add a project `README.md` and `AGENTS.md`, then update the root layout and architecture docs.

## Completion checks

Before reporting completion:

1. Run the narrowest relevant project tests during development.
2. Run `pnpm exec nx affected -t lint test --base=origin/main --parallel=3`.
3. Run Lens diagnostics for edited source files and resolve new blockers.
4. Recheck that documentation and `docs/ARCHITECTURE.md` describe the resulting behavior.
5. Report commands run, outcomes, and any residual risk.

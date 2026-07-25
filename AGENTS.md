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

## Agent workflow

1. Read this file, the nearest project `AGENTS.md`, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), and [`docs/standards/documentation.md`](docs/standards/documentation.md) before editing.
2. For non-trivial work, use `pi-subagents` to prepare a canonical draft at `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md` and a matching chain at `.pi/chains/saved-plans/YYYY_MM_DD_HHMM-slug.chain.json`. Use `record-plan-draft` to create or update the `📝 draft` index row; the user reviews the Markdown plan and chain in an editor. After explicit user approval, use `save-approved-plan` to promote the row to `⬜ not started`. Never copy, move, or alter the approved plan or its supporting artifacts; check off its implementation steps in that same file as they are completed. `.pi/chains/saved-plans/` is reserved for plan-specific execution chains: run one only when its linked canonical plan has explicit user approval and is registered in the plan index. The parent verifies those preconditions; chain discovery does not enforce them.
3. For behavior changes, use RED, GREEN, REFACTOR and confirm the failing test fails for the intended reason. Documentation-, configuration-, formatting-, generated-code, and sandbox-prototype changes are exceptions; state the exception.
4. Choose work directly only for local, clear, low-risk work. Otherwise follow the [delegation workflow](docs/coding-agent-harness/delegation.md): scout and plan normal work; add oracle review for risky or ambiguous decisions; use parallel read-only discovery for broad separable work.
5. The parent session owns decisions and synthesis. Keep one writer in a shared checkout; use fresh, read-only reviewers for independent feedback. Use `worktree: true` only for intentional parallel writing from a clean tree.
6. Assess documentation impact for every behavior, API, configuration, architecture, or workflow change. During implementation, capture durable conclusions from approved plans and their supporting artifacts in the appropriate living documentation. Use the project `technical-writer` when the resulting documentation work is substantial, cross-file, or user-facing; otherwise update the relevant documentation directly. Follow [`docs/coding-agent-harness/workflows.md`](docs/coding-agent-harness/workflows.md) for planning, review, MCP, and completion detail.

## Nx workflow

- Use Nx generators, with `--dry-run` first, for projects and generated workspace structure. Never hand-write a new `project.json`.
- Give source projects consistent `lint`, `lint:fix`, `format`, `format:fix`, and `test` targets plus `serve`/`build` where applicable. Verify with `pnpm exec nx show project <name> --json`.
- Add a project `README.md` and `AGENTS.md`, then update the root layout and architecture docs.

## Completion checks

Before reporting completion:

1. Run the narrowest relevant project tests during development.
2. Run the builtin reviewer for code changes and resolve accepted blocking findings.
3. Run `pnpm exec nx affected -t lint test --base=origin/main --parallel=3`.
4. Run Lens diagnostics for edited source files and resolve new blockers.
5. Recheck that documentation and `docs/ARCHITECTURE.md` describe the resulting behavior, validate changed links, and involve `technical-writer` when the documentation impact is substantial, cross-file, or user-facing.
6. Report commands run, outcomes, and any residual risk.

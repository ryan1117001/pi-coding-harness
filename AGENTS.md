# Workspace agent policy

## Scope

- Read the nearest project `AGENTS.md` before changing files under `projects/`; project instructions refine this file.
- Use [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the repository map and service topology.
- Use [`docs/standards/documentation.md`](docs/standards/documentation.md) for documentation conventions.

| Area                 | Instructions                                                 |
| -------------------- | ------------------------------------------------------------ |
| Web SPA              | [`projects/web/AGENTS.md`](projects/web/AGENTS.md)           |
| Web end-to-end tests | [`projects/web-e2e/AGENTS.md`](projects/web-e2e/AGENTS.md)   |
| FastAPI service      | [`projects/api/AGENTS.md`](projects/api/AGENTS.md)           |
| PostgreSQL image     | [`projects/postgres/AGENTS.md`](projects/postgres/AGENTS.md) |

## Change policy

- Use test-driven development for features, bug fixes, and behavior changes: RED, GREEN, REFACTOR. Confirm the failing test fails for the intended reason. Exceptions are generated code, sandbox prototypes, and config-, documentation-, or formatting-only changes; state the exception.
- Update documentation in the same change when behavior, APIs, configuration, architecture, or developer workflow changes.
- Keep browser code behind its own backend boundary. Record every new network dependency or service connection in `docs/ARCHITECTURE.md`; write a design document first when the connection changes architecture.
- Keep edits narrow. Do not add dependencies, infrastructure, or speculative abstractions without an approved requirement.

## Dev Container agents

- Trusted agents may use the Compose-backed [Dev Container workspace](.devcontainer/README.md) through its headless workflow. It starts `workspace` and `postgres`; run API and web servers with Nx inside `workspace`.
- Docker-outside-of-Docker grants host-daemon authority. It is not a sandbox for untrusted agents or repository code. Do not persist provider, Git, SSH, or Pi credentials in the image, repository, or named volumes; use ephemeral runner-provided credentials when required.
- The explicit [host Pi opt-in](.devcontainer/README.md#opt-in-to-user-level-pi-extensions) exposes only read-only user settings and extensions to trusted workspace processes. It never exposes `auth.json`; inspect global settings before opting in and keep provider credentials in the invoked process environment.
- Host development remains supported. See [`.devcontainer/README.md`](.devcontainer/README.md) for exact commands, browser scope, cache reset, and safe teardown.
- [Docker Sandbox Pi](docs/references/docker-sandbox-pi.md) is a separate optional manual runtime. It requires exact `sbx` 0.38.0 and authorized live smoke; generic CI runs only `pnpm sandbox:test`. It does not make the Dev Container or ordinary checkout isolated.

## Agent workflow

1. Read this file, the nearest project `AGENTS.md`, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), and [`docs/standards/documentation.md`](docs/standards/documentation.md) before editing.
2. For non-trivial work, use `pi-subagents` to prepare a canonical draft at `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md` and a matching chain at `.pi/chains/saved-plans/YYYY_MM_DD_HHMM-slug.chain.json`. Use `record-plan-draft` to create or update the `📝 draft` index row; the user reviews the Markdown plan and chain in an editor. After explicit user approval, use `save-approved-plan` to promote the row to `⬜ not started`. Never copy, move, or alter the approved plan or its supporting artifacts; check off its implementation steps in that same file as they are completed. `.pi/chains/saved-plans/` is reserved for plan-specific execution chains: run one only when its linked canonical plan has explicit user approval and is registered in the plan index. The parent verifies those preconditions; chain discovery does not enforce them.
3. For behavior changes, use RED, GREEN, REFACTOR and confirm the failing test fails for the intended reason. Documentation-, configuration-, formatting-, generated-code, and sandbox-prototype changes are exceptions; state the exception.
4. Choose work directly only for local, clear, low-risk work. Otherwise follow the [delegation workflow](docs/coding-agent-harness/delegation.md): scout and plan normal work; add oracle review for risky or ambiguous decisions; use parallel read-only discovery for broad separable work.
5. The parent session owns decisions and synthesis. Keep one writer in a shared checkout; use fresh, read-only reviewers for independent feedback. Use `worktree: true` only for intentional parallel writing from a clean tree.
6. Assess documentation impact for every behavior, API, configuration, architecture, or workflow change. During implementation, capture durable conclusions from approved plans and their supporting artifacts in the appropriate living documentation. Use the project `technical-writer` when the resulting documentation work is substantial, cross-file, or user-facing; otherwise update the relevant documentation directly. Follow [`docs/coding-agent-harness/workflows.md`](docs/coding-agent-harness/workflows.md) for planning, review, MCP, and completion detail.

## Nx workflow

- Use Nx generators, with `--dry-run` first, for projects and generated workspace structure. Never hand-write a new `project.json`.
- Give projects consistent `lint`, `lint:fix`, `format`, and `format:fix` targets when they own lintable/formattable source. Use `test` for unit and contract suites, `e2e` for end-to-end projects, and `serve`/`build` where applicable. Verify with `pnpm exec nx show project <name> --json`.
- Add a project `README.md` and `AGENTS.md`, then update the root layout and architecture docs.

## Completion checks

Before reporting completion:

1. Run the narrowest relevant project tests during development.
2. Run the builtin reviewer for code changes and resolve accepted blocking findings.
3. Run `pnpm exec nx affected -t lint test --base=origin/main --parallel=3`.
4. Run Lens diagnostics for edited source files and resolve new blockers.
5. Recheck that documentation and `docs/ARCHITECTURE.md` describe the resulting behavior, validate changed links, and involve `technical-writer` when the documentation impact is substantial, cross-file, or user-facing.
6. Report commands run, outcomes, and any residual risk.

<!-- nx configuration start-->
<!-- Leave the start & end comments to automatically receive updates. -->

## General Guidelines for working with Nx

- For navigating/exploring the workspace, invoke the `nx-workspace` skill first - it has patterns for querying projects, targets, and dependencies
- When running tasks (for example build, lint, test, e2e, etc.), always prefer running the task through `nx` (i.e. `nx run`, `nx run-many`, `nx affected`) instead of using the underlying tooling directly
- Prefix nx commands with the workspace's package manager (e.g., `pnpm nx build`, `npm exec nx test`) - avoids using globally installed CLI
- You have access to the Nx MCP server and its tools, use them to help the user
- For Nx plugin best practices, check `node_modules/@nx/<plugin>/PLUGIN.md`. Not all plugins have this file - proceed without it if unavailable.
- NEVER guess CLI flags - always check nx_docs or `--help` first when unsure

## Scaffolding & Generators

- For scaffolding tasks (creating apps, libs, project structure, setup), ALWAYS invoke the `nx-generate` skill FIRST before exploring or calling MCP tools

## When to use nx_docs

- USE for: advanced config options, unfamiliar flags, migration guides, plugin configuration, edge cases
- DON'T USE for: basic generator syntax (`nx g @nx/react:app`), standard commands, things you already know
- The `nx-generate` skill handles generator discovery internally - don't call nx_docs just to look up generator syntax

<!-- nx configuration end-->

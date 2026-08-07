---
status: approved
---

# Modernize and simplify the repository template

## Goal

Bring the template to a clean, current, reproducible baseline. Fix broken validation, remove unused or misleading starter material, update compatible dependencies, harden the database bootstrap path, and reduce documentation duplication so humans and coding agents can find one canonical answer quickly.

## Review summary

The repository has a sound small-project layout, current major platform choices, a clean Git worktree, synchronized Nx configuration, passing API tests, and a successful web production build. The baseline is not release-ready because core web tests and typechecking fail, Biome cannot check the tracked tree cleanly, the configured AI-agent files are stale according to Nx, and several template contracts disagree with the actual targets or files.

### Highest-priority findings

1. **Web validation is red.** `pnpm exec nx run-many -t lint test build typecheck --skipNxCache` fails in `web:test` because route tests render an empty body and in `web:typecheck` because project-reference outputs are missing and Storybook callback parameters lose their types. The affected test setup is duplicated in [`projects/web/src/routes/__root.test.tsx`](../../../projects/web/src/routes/__root.test.tsx) and [`projects/web/src/routes/index.test.tsx`](../../../projects/web/src/routes/index.test.tsx); the TypeScript references are defined in [`projects/web/tsconfig.json`](../../../projects/web/tsconfig.json), [`tsconfig.app.json`](../../../projects/web/tsconfig.app.json), [`tsconfig.spec.json`](../../../projects/web/tsconfig.spec.json), and [`tsconfig.storybook.json`](../../../projects/web/tsconfig.storybook.json).
2. **The root quality command is not clean.** [`biome.json`](../../../biome.json) still references the 2.4.8 schema while the installed CLI is 2.5.4, uses a deprecated linter configuration, formats tracked configuration differently, and tries to parse a JavaScript-like example stored as `example.chain.json`. The root `biome` script is also easy to invoke incorrectly because it already embeds `check .`.
3. **Template agent configuration is stale.** `pnpm exec nx configure-ai-agents --check=all` reports updates for Codex, Copilot, OpenCode, and Cursor. Nx also prints an outdated-agent warning during normal task execution. Any generated changes must be reviewed against the repository's canonical [`AGENTS.md`](../../../AGENTS.md) and Pi-specific policy instead of accepted blindly.
4. **The PostgreSQL bootstrap interpolates untrusted identifiers into SQL.** [`projects/postgres/init-databases.sh`](../../../projects/postgres/init-databases.sh) inserts each environment-provided database name directly into SQL. It also uses Bash features while [`projects/postgres/AGENTS.md`](../../../projects/postgres/AGENTS.md) says initialization scripts are POSIX-shell compatible. The script needs an explicit identifier contract, safe quoting, and tests.
5. **Declared project-target conventions do not match reality.** Root policy requires source projects to expose `lint`, `lint:fix`, `format`, `format:fix`, and `test`, but resolved Nx configuration shows `web` lacks the fix/format targets, `web-e2e` lacks test/fix/format targets, and `postgres` exposes only `lint`. The pre-commit hook in [`.pre-commit-config.yaml`](../../../.pre-commit-config.yaml) therefore does not provide the uniform behavior its name implies.
6. **There is avoidable dead weight and configuration drift.** [`projects/web/package.json`](../../../projects/web/package.json) declares unused `zustand`; [`nx.json`](../../../nx.json) registers `@nx/vitest` twice; [`tools/release.mts`](../../../tools/release.mts) and [`tools/coverage-report.ts`](../../../tools/coverage-report.ts) have no tracked caller; and [`.gitignore`](../../../.gitignore) is a long generic accumulation with duplicate Nx entries and unrelated framework sections.
7. **Documentation checks have scope and link problems.** The Markdown command traverses vendored skills, runtime artifacts, virtual environments, generated Paraglide output, and nested package content unless callers hand-maintain exclusions. Two tracked custom agent prompts fail normal Markdown rules, one skill link is genuinely broken, and the commented sample row in [`docs/prompts/README.md`](../README.md) is reported as a missing target by simple link checkers.
8. **Package dependencies need a controlled latest-version migration with Nx's TypeScript 7 compatibility setup.** `pnpm outdated --long` reports updates across Biome, Nx, Storybook, Playwright, Vite, React, TanStack, daisyUI, TypeScript, Node types, and related packages. The implementation must move direct and development dependencies to their latest stable releases, including new majors. Because TypeScript 7 lacks the programmatic API required by `@nx/js/typescript`, Vite, and related tooling, adopt the [Nx-supported side-by-side setup](https://nx.dev/docs/kb/typescript-7): TypeScript 7 provides `tsc`, while TypeScript 6 remains available as the `typescript` package and `tsc6` compatibility API. Runtime-coupled packages such as `@types/node` must match the supported runtime rather than an unrelated newer runtime line. Apache AGE should move to the latest verified PG18-compatible release when available.
9. **CI coverage is narrow.** The only tracked GitHub Actions workflow validates the Dev Container. A template needs a normal quality workflow for install, sync check, lint, typecheck, tests, and builds, with browser installation scoped to jobs that require it.

## Workflow

The matching plan-specific [saved chain](../../../.pi/chains/saved-plans/2026_08_06_1934-modernize-and-simplify-template.chain.json) performs a fresh baseline check, serial TDD implementation by milestone, documentation consolidation, parallel correctness and simplicity review, one serial fix pass, and final validation. It must not run until this plan has explicit user approval and is registered in the plan index.

The current machine cannot start subagents because a user-level `pi-permission-system` extension is missing its `package.json`. Repair, remove, or disable that incomplete user extension before running the saved chain. This environment issue is not a repository change.

## Decisions

- Keep the existing Nx, React, Vite, FastAPI, PostgreSQL, Dev Container, and Pi-harness architecture.
- Upgrade every direct and development package dependency to the latest stable release available at implementation time, including major versions. Adopt TypeScript 7 alongside the TypeScript 6 compatibility API exactly as documented by Nx. Use official migration tooling and update adjacent code, configuration, tests, and documentation to complete each migration.
- Keep `packageManager`, Docker tool pins, Nx installation metadata, lockfiles, and documentation synchronized.
- Treat vendored or generated Agent Skills as upstream material. Exclude them from repository-authored Markdown/format gates unless this repository intentionally owns a local patch.
- Keep one canonical location for each fact: root onboarding in `README.md`, contribution workflow in `CONTRIBUTING.md`, mandatory agent policy in `AGENTS.md`, current topology in `docs/ARCHITECTURE.md`, operational detail in project READMEs, and agent-only project constraints in project `AGENTS.md` files.
- Prefer deleting unused starter dependencies, scripts, comments, and placeholder directories over documenting hypothetical future use.
- Preserve the browser-to-backend boundary. This plan introduces no new service connection.

## Non-goals

- Do not redesign the sample UI or add product features.
- Do not add a new framework, service, database, state-management abstraction, component library, or CI vendor.
- Do not replace the root TypeScript 6 compatibility package with TypeScript 7 while TypeScript 7 lacks the programmatic API required by Nx and Vite. Do not adopt prerelease package versions when a stable compatible release exists or retain another outdated package silently; document the blocker and request a decision.
- Do not rewrite archived approved plans or generated route/Paraglide files by hand.
- Do not make the Dev Container depend on user-level Pi state or credentials.

## Steps

- [x] **1. Capture reproducible failing baselines and define the validation matrix.**
  - Record uncached results for Nx sync, project target discovery, web tests, web and E2E typechecking, API tests, Biome, Markdown, local-link validation, Compose rendering, and AI-agent configuration checks.
  - Separate repository-authored inputs from generated, vendored, runtime, dependency, and archived-plan artifacts.
  - Acceptance: every known failure is reproducible for the intended reason and mapped to one later step.

- [x] **2. Repair web tests and TypeScript project references using RED, GREEN, REFACTOR.**
  - Add or refactor one shared router-test harness that waits for the router to load and prevents query/router state leakage.
  - Fix the `scrollTo` test-environment warning at the browser boundary rather than suppressing unrelated errors.
  - Correct the app/spec/Storybook project-reference contract so clean typechecking does not depend on stale declaration output and Storybook `play` context remains typed.
  - Keep route registration and Paraglide output generated.
  - Acceptance: uncached `web:test`, `web:typecheck`, `web-e2e:typecheck`, and `web:build` pass from a clean generated-output state.

- [x] **3. Normalize quality tooling and project targets.**
  - Run the supported Biome migration, update its schema, remove deprecated settings, and scope checks to repository-owned files.
  - Give applicable projects consistent check/fix/format/test targets or narrow the root policy and pre-commit hook where a target is not meaningful. Ensure names describe actual behavior.
  - Remove the duplicate Vitest plugin registration and make root scripts unambiguous.
  - Rename or convert the non-JSON example artifact so JSON tools do not parse invalid syntax.
  - Acceptance: root formatting/lint commands, pre-commit commands, `nx sync:check`, and JSON/YAML/TOML syntax checks pass without hand-written exclusion lists.

- [x] **4. Upgrade packages to their latest stable releases and adopt Nx's TypeScript 7/6 setup.**
  - Capture machine-readable npm and Python dependency baselines before changing versions, including direct, development, and locked transitive packages.
  - Use `nx migrate latest` for Nx and review generated migrations before applying them.
  - Upgrade every npm direct and development dependency to its latest stable release in compatibility groups, including new majors. Configure `@typescript/native` as `npm:typescript@^7.0.2` and `typescript` as `npm:@typescript/typescript6@^6.0.2`, using the latest compatible patch releases available during implementation.
  - Verify that `pnpm exec tsc --version` reports TypeScript 7 and `pnpm exec tsc6 --version` reports TypeScript 6. Keep programmatic consumers such as `@nx/js/typescript` and Vite on the TypeScript 6 API while Nx inferred build and typecheck tasks use the TypeScript 7 compiler.
  - Upgrade Python direct and development requirements to their latest stable releases and regenerate `projects/api/uv.lock` with uv; remove superseded tooling rather than carrying duplicate formatters or test utilities.
  - Upgrade runtime-coupled type packages to the newest stable line matching the repository's supported runtime, or update that runtime deliberately when required by the approved package migration.
  - Check package-managed Docker and tool pins, including pnpm, uv, Dev Container CLI, nginx, PostgreSQL extensions, and Apache AGE; use the latest stable compatible release and document any unavoidable prerelease or external compatibility constraint.
  - Validate after each compatibility group so migration failures are attributable and reversible.
  - Acceptance: package and Python lockfiles are regenerated by their owning tools, all in-scope direct dependencies are at their latest stable compatible releases, `tsc` reports TypeScript 7, `tsc6` reports TypeScript 6, Nx project discovery and the full validation matrix pass with both installed, and any additional outdated or prerelease dependency has a specific documented blocker requiring user disposition.

- [x] **5. Harden and simplify API/PostgreSQL starter behavior using TDD.**
  - Add shell-level tests for empty, single, multiple, invalid, quoted, and injection-like database names before changing initialization.
  - Enforce a clear database-name grammar or use safe psql identifier quoting; remove raw interpolation.
  - Make the shell contract match the implementation by choosing POSIX `sh` or explicitly documenting Bash.
  - Review whether the separate status endpoint and repository abstraction add useful template value; keep only behavior that teaches a real boundary.
  - Remove unused Python development tools such as `autopep8` when Ruff is the documented owner.
  - Acceptance: API tests and coverage pass, initialization tests prove safe behavior, and container builds remain non-root and reproducible.

- [x] **6. Remove dead template material and tighten ignore files.**
  - Remove unused `zustand` unless a real sample store is added for an approved requirement.
  - Verify tracked callers before deleting or wiring `tools/release.mts` and `tools/coverage-report.ts`; prefer deletion if no supported workflow uses them.
  - Replace the generic `.gitignore` accumulation with a short workspace-specific file and remove duplicate entries.
  - Remove generated placeholder directories or comments that do not demonstrate supported behavior.
  - Acceptance: dependency/dead-file analysis is explained, installs remain reproducible, and no supported command loses required files.

- [x] **7. Simplify living documentation for humans and agents.**
  - Rewrite the root onboarding path around the shortest successful host and Dev Container flows.
  - Deduplicate command lists between README, CONTRIBUTING, project READMEs, and project AGENTS; link to the canonical owner instead.
  - Keep agent files focused on mandatory constraints and decision boundaries, not general tutorials.
  - Scope Markdown and local-link checks to tracked repository-authored documentation while retaining targeted validation for locally maintained prompts and skills.
  - Fix genuine broken links and make example-only links non-actionable to validators.
  - Update dependency/version statements, target tables, architecture, environment variables, and CI instructions to match the final repository.
  - Acceptance: all canonical links resolve, Markdown gates pass, and each common task has one obvious starting document.

- [x] **8. Add a normal repository quality workflow.**
  - Add least-privilege CI for frozen install, Nx sync check, lint, typecheck, tests, builds, and documentation checks.
  - Install only the browsers required by the selected test job and keep the heavier Dev Container workflow separate.
  - Use Nx caching locally without requiring Nx Cloud.
  - Acceptance: the workflow exercises the same documented commands and has no credential or host-Pi dependency.

- [x] **9. Refresh supported AI-agent configuration deliberately.**
  - Run `nx configure-ai-agents --check=all`, select only agent surfaces intentionally supported by the template, and review generated files against Pi's canonical policy.
  - Do not duplicate or weaken `AGENTS.md`, project instructions, plan approval gates, or the browser/backend boundary.
  - Acceptance: the selected Nx agent checks report current, unsupported agent files are absent, and Pi continues loading the intended repository policy.

- [x] **10. Complete review and final validation.**
  - Run independent correctness/security and simplicity/documentation reviews.
  - Apply accepted fixes through one writer, rerun affected checks, inspect generated diffs, and confirm no unapproved architecture change or unexplained outdated package remains.
  - Acceptance: all required commands pass, reviewer blockers are resolved, the final diff is narrower than the problems it fixes, and residual risks are documented.

## Verification

```bash
pnpm install --frozen-lockfile
pnpm exec tsc --version
pnpm exec tsc6 --version
pnpm exec nx sync:check
pnpm exec nx show projects --json
pnpm exec nx run-many -t lint typecheck test build --parallel=3 --skipNxCache
pnpm exec nx affected -t lint test --base=origin/main --parallel=3
pnpm biome
pnpm exec markdownlint-cli2 <tracked-repository-documentation>
pnpm exec nx configure-ai-agents --check=all
docker compose config --quiet
bash -n .devcontainer/*.sh projects/postgres/init-databases.sh
.pi/tests/verify-plan-lifecycle.sh
git diff --check
git status --short
```

Run the focused PostgreSQL initialization contract tests, Dev Container host-Pi contract tests, and Docker image smoke tests added or retained by the implementation. Run Lens diagnostics on edited source files before completion.

## Documentation impact

This work changes dependency versions, quality commands, project targets, CI, template onboarding, and agent setup. Update `README.md`, `CONTRIBUTING.md`, relevant project READMEs and AGENTS files, `docs/ARCHITECTURE.md`, `docs/references/`, and coding-agent-harness documentation in the same change. No new service connection is planned.

## Risks and recovery

- **Coupled tool upgrades:** update one compatibility group at a time and revert the last group if its focused checks fail.
- **TypeScript dual-toolchain drift:** TypeScript 7 supplies the compiler while TypeScript 6 supplies the programmatic API used by Nx, Vite, and related tools. Keep both aliases explicit, verify both compiler commands, and test Nx project discovery before build, typecheck, test, and lint targets.
- **Generated-file churn:** regenerate only through owning tools and review generated diffs separately.
- **PostgreSQL extension availability:** retain the existing AGE tag if no verified stable PG18 release exists; make the pre-release status explicit.
- **Over-simplification:** verify every deletion against tracked callers, documented commands, CI, Compose, and Nx resolved targets.
- **Subagent startup failure:** repair the incomplete user-level permission extension before chain execution; do not patch repository policy around a broken host extension.

## Assumptions requiring approval

- Latest stable major versions of direct and development package dependencies are in scope, including required code and configuration migrations. TypeScript 7 and the TypeScript 6 compatibility API are both deliberate root development dependencies.
- The approved TypeScript setup follows Nx's side-by-side aliases until TypeScript 7 exposes the programmatic API required by the workspace. If another latest stable package is mutually incompatible or conflicts with a supported runtime, implementation must present the exact blocker for user disposition instead of silently retaining an older version.
- Unused dependencies and scripts may be removed when no tracked workflow or documented contract uses them.
- A normal quality CI workflow should be added alongside the existing Dev Container workflow.
- Documentation may be substantially shortened when canonical information remains available through clear links.

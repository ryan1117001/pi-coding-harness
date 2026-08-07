# Nx Guidelines

Conventions for Nx task names, project scaffolding, and CI integration in this repo. Follow these when adding or editing `projects/<name>/project.json`.

## Recommended targets (source projects)

For projects that ship **lintable or formattable source** (Python with Ruff, Node/TypeScript with Biome or ESLint, etc.), define these targets so `nx run-many` and CI stay consistent:

| Target       | Purpose                                             |
| ------------ | --------------------------------------------------- |
| `lint`       | **Check only** — exit non-zero if fixes are needed. |
| `lint:fix`   | Auto-fix what the linter can fix.                   |
| `format`     | **Check only** for the formatter.                   |
| `format:fix` | Apply formatting.                                   |

Do **not** use a check-only `format` target to write files in automation: keep **check** vs **write** separate.

## Infra-only projects

Infrastructure projects may omit write-oriented format targets. End-to-end projects use the conventional `e2e` target instead of duplicating it as `test`; infrastructure projects add `test` only when they own a meaningful contract test.

## Verification

- `pnpm exec nx show project <name> --json` — inspect inferred and declared targets.
- Run targets directly before wiring them into CI or hooks.

## Pre-commit

Root `.pre-commit-config.yaml` runs available `lint:fix` and `format:fix` targets, then the meaningful unit/contract tests for `web`, `api`, and `postgres`. End-to-end coverage remains the explicit `web-e2e:e2e` target.

## Coverage and release tooling

After project tests produce Cobertura XML under `coverage/projects/`, run `pnpm coverage:report` to generate the workspace dashboard at `coverage/index.html`. The dashboard links to each available project-level HTML report.

The release pipeline runs `pnpm release` from a clean worktree. [`tools/release.mts`](../../tools/release.mts) uses Nx Release, conventional commits, project metadata, and per-project tags to emit the changed Docker-image matrix through GitHub Actions outputs. Use `pnpm release --dry-run` in a clean checkout to preview version and changelog decisions without writing them; the script refuses dirty worktrees so Nx Release cannot reset unrelated local changes.

## TypeScript toolchain

`@typescript/native` aliases TypeScript 7 and supplies the `tsc` binary used by inferred Nx typecheck/build tasks. The `typescript` package aliases `@typescript/typescript6` so Nx, Vite, and other programmatic compiler consumers retain the TypeScript 6 API; its compatibility compiler is available as `tsc6`.

`@types/node` stays on the Node 24 line because Node 24.19.0 is the supported runtime; a newer type line would describe APIs unavailable in that runtime.

## Scaffolding new projects

Always use Nx generators — never hand-write `project.json` from scratch. Generators ensure targets, configs, and workspace wiring are consistent.

```bash
# React app (Vite + Vitest + Playwright e2e)
pnpm exec nx g @nx/react:application \
  --directory=projects/<name> \
  --bundler=vite \
  --style=css \
  --no-interactive

# Python (uv) project with Ruff linting
pnpm exec nx g @nxlv/python:uv-project \
  --name=<name> \
  --directory=projects/<name> \
  --buildSystem=uv \
  --linter=ruff \
  --no-interactive
```

**Always dry-run first:** add `--dry-run` to verify file placement before generating for real.

**After generating a React app:** add a `test:` block to `vite.config.mts` so the `@nx/vitest` plugin infers the `test` target automatically:

```typescript
test: {
  globals: true,
  environment: 'jsdom',
  include: ['src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
  reporters: ['default'],
  coverage: {
    reportsDirectory: '../../coverage/projects/<name>',
    provider: 'v8',
    reporter: ['html', 'cobertura'],
  },
},
```

Use the `nx-generate` skill for step-by-step scaffolding guidance.

## Skills

Use the `nx-workspace` skill to explore project configuration, the `nx-run-tasks` skill to run targets, and `nx-generate` for scaffolding new projects.

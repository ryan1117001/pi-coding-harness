# Nx Guidelines

Conventions for Nx task names, project scaffolding, and CI integration in this repo. Follow these when adding or editing `projects/<name>/project.json`.

## Recommended targets (source projects)

For projects that ship **lintable or formattable source** (Python with Ruff, Node/TypeScript with Biome or ESLint, etc.), define these targets so `nx run-many` and CI stay consistent:

| Target | Purpose |
|--------|---------|
| `lint` | **Check only** — exit non-zero if fixes are needed. |
| `lint:fix` | Auto-fix what the linter can fix. |
| `format` | **Check only** for the formatter. |
| `format:fix` | Apply formatting. |

Do **not** use a check-only `format` target to write files in automation: keep **check** vs **write** separate.

## Infra-only projects

Infrastructure-only projects (Docker Compose services, etc.) may omit application `lint`/`format` targets; they are not source packages in the same sense.

## Verification

- `pnpm exec nx show project <name> --json` — inspect inferred and declared targets.
- Run targets directly before wiring them into CI or hooks.

## Pre-commit

Root `.pre-commit-config.yaml` runs **`nx run-many --targets=lint:fix,format:fix,test`** across all projects. When you add Node/TS or Python apps, make sure they expose those targets so the hook covers them.

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

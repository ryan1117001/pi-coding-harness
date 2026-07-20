# Agent skills

Pi discovers [`../../.agents/skills/`](../../.agents/skills/) natively. Do not add host-specific skill symlinks or duplicate the directory in `.pi/settings.json`.

## Provenance

[`skills-lock.json`](../../skills-lock.json) records the upstream repository, source path, and computed hash for 11 vendored skills. Treat those directories as read-only snapshots: update them through their upstream synchronization process and update the lock entry atomically.

Local skills are intentionally absent from the lockfile and may be edited in this repository:

| Skill | Purpose |
| --- | --- |
| `codebase-analysis` | Evidence-backed exploration and structural review criteria; preloaded by the builtin reviewer override. |
| `multi-stage-dockerfile` | Focused multi-stage container-image guidance. |
| `save-approved-plan` | Validates and registers the already-canonical Plannotator plan without copying it. |
| `webapp-testing` | Browser interaction and debugging with the installed Playwright stack. |

## Retained upstream skills

| Area | Skills |
| --- | --- |
| Nx and workspace packages | `nx-generate`, `nx-run-tasks`, `nx-workspace`, `link-workspace-packages` |
| Package management | `pnpm` |
| UI construction and review | `building-components`, `frontend-design`, `web-design-guidelines` |
| Testing | `test-driven-development`, `python-testing-patterns` |
| Data modeling | `postgresql-table-design` |

The former local Storybook skill is absent because its testing imports and addon recommendations predate this repository's Storybook 10 setup. Current story conventions live in [`projects/web/AGENTS.md`](../../projects/web/AGENTS.md).

Packages may supply additional versioned skills, such as web research or Lens rule authoring. Those remain owned by their pinned package and are not copied into `.agents/skills/`.

## Selection rules

- Let Pi load a skill on demand from its description, or invoke `/skill:<name>` when a workflow explicitly requires it.
- Keep always-on policy in `AGENTS.md`, not in a skill.
- Keep project-specific commands and stack constraints in the nearest project `AGENTS.md`.
- Remove a skill only when its contract is demonstrably obsolete, harmful, or fully covered by a narrower maintained source; uncertainty favors retention.

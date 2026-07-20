# Pi coding harness

This repository configures Pi through tracked project files while keeping installed packages and session artifacts local.

## Bootstrap

1. Install Pi 0.80.10 or a compatible newer release.
2. Clone the repository and run `pnpm install`.
3. Start `pi` from the repository root.
4. Review and accept Pi's project-trust prompt. Trust permits `.pi/settings.json`, project resources, and automatic installation of the pinned packages.
5. Restart Pi after the initial package installation if a package requests it.

For non-interactive validation, pass `pi --approve`. Do not set a repository-wide global trust default.

Pi installs missing project packages under ignored `.pi/npm/`. A clean checkout is reproducible from `.pi/settings.json`; do not commit `.pi/npm/package.json`, its lockfile, or `node_modules`.

## Tracked surfaces

| Surface | Location | Purpose |
| --- | --- | --- |
| Workspace policy | [`AGENTS.md`](../../AGENTS.md) | Cross-workspace change and completion rules |
| Project policy | `projects/*/AGENTS.md` | Stack, boundaries, commands, and tests |
| Packages | [`.pi/settings.json`](../../.pi/settings.json) | Exact package versions, resource filters, overrides |
| Planning | [`.pi/plannotator.json`](../../.pi/plannotator.json) | Canonical plan path and approval handoff |
| Project agents | [`.pi/agents/`](../../.pi/agents/) | Roles not covered by package builtins |
| Prompt templates | [`.pi/prompts/`](../../.pi/prompts/) | Unique repeatable repository checks |
| Skills | [`.agents/skills/`](../../.agents/skills/) | Agent Skills discovered natively by Pi |
| MCP | [`.mcp.json`](../../.mcp.json) | Shared project MCP endpoints |

## Documentation

- [extensions.md](extensions.md) — pinned third-party packages and why each remains.
- [skills.md](skills.md) — retained skill catalog and provenance rules.
- [workflows.md](workflows.md) — planning, delegation, review, and verification.

Secrets and user preferences stay in user-level Pi configuration or environment variables. Project files contain no provider keys, model credentials, or trust decisions.

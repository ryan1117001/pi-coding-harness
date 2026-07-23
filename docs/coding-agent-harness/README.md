# Coding-agent harness

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
| Packages and runtime profiles | [`.pi/settings.json`](../../.pi/settings.json) | Exact package pins, file-tool behavior, and subagent profiles |
| Planning | [`.pi/plannotator.json`](../../.pi/plannotator.json) | Canonical plan path and approval handoff |
| Project agents | [`.pi/agents/`](../../.pi/agents/) | Roles not covered by package builtins |
| Prompt templates | [`.pi/prompts/`](../../.pi/prompts/) | Unique repeatable repository checks |
| Skills | [`.agents/skills/`](../../.agents/skills/) | Agent Skills discovered natively by Pi |
| MCP | [`.mcp.json`](../../.mcp.json) | Shared project MCP endpoints |

## Documentation

| Need | Read |
| --- | --- |
| Package purpose and upgrade checks | [extensions.md](extensions.md) |
| Configuration consumers and runtime boundaries | [configuration.md](configuration.md) |
| Retained skill catalog and provenance | [skills.md](skills.md) |
| Planning, delegation, review, and verification | [workflows.md](workflows.md) and [delegation.md](delegation.md) |

Secrets and user preferences stay in user-level Pi configuration or environment variables. Project files contain no provider keys, model credentials, or trust decisions.

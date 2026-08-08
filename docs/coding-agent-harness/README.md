# Coding-agent harness

This repository configures Pi through tracked project files while keeping installed packages and session artifacts local.

## Bootstrap

1. Install a compatible Pi release.
2. Clone the repository and run `pnpm install`.
3. Start `pi` from the repository root.
4. Review and accept Pi's project-trust prompt. Trust permits `.pi/settings.json`, project resources, and automatic installation of the configured project packages.
5. Restart Pi after the initial package installation if a package requests it.

For non-interactive validation, pass `pi --approve`. Do not set a repository-wide global trust default.

Pi installs missing project packages listed in `.pi/settings.json` under ignored `.pi/npm/`. Do not commit `.pi/npm/package.json`, its lockfile, or `node_modules`.

## Dev Container

The optional [Dev Container workspace](../../.devcontainer/README.md) installs the pinned Pi release during its non-interactive setup. It does not start Pi or accept project trust. When a user starts Pi in the container, the same project-trust prompt and [`.pi/settings.json`](../../.pi/settings.json) package configuration apply. The workspace has host-Docker authority and is only for trusted humans and agents; provide credentials ephemerally rather than through project files or persistent Pi state.

## Docker Sandbox

The optional [Docker Sandbox Pi runtime](../references/docker-sandbox-pi.md) uses the same repository-managed `@earendil-works/pi-coding-agent@0.84.1` authority as the Dev Container, but it is a separate manual runtime. Its writable Pi state remains in the Sandbox VM. Its optional user settings/extensions input is a trusted read-only snapshot and directory pair, not a host Pi home or authentication share. The exact `sbx` 0.38.0 evidence bounds its lifecycle claims.

## Tracked surfaces

| Surface | Location | Purpose |
| --- | --- | --- |
| Workspace policy | [`AGENTS.md`](../../AGENTS.md) | Cross-workspace change and completion rules |
| Project policy | `projects/*/AGENTS.md` | Stack, boundaries, commands, and tests |
| Packages and file-tool settings | [`.pi/settings.json`](../../.pi/settings.json) | Configured package set and ReadSeek behavior |
| Subagent profiles | `~/.pi/agent/profiles/pi-subagents/` | User-level model, thinking, fallback, and watchdog settings |
| Planning | [`docs/prompts/`](../prompts/README.md), [`.pi/prompts/draft-plan.md`](../../.pi/prompts/draft-plan.md), and [`.pi/chains/`](../../.pi/chains/README.md) | Canonical drafts, lifecycle guidance, and saved-chain namespaces |
| Project agents | [`.pi/agents/`](../../.pi/agents/) | Roles not covered by package builtins |
| Prompt templates | [`.pi/prompts/`](../../.pi/prompts/) | Unique repeatable repository checks |
| Skills | [`.agents/skills/`](../../.agents/skills/) | Agent Skills discovered natively by Pi |
| MCP | [`.mcp.json`](../../.mcp.json) | Shared project MCP endpoints |
| Pi runtime authority | [`tools/toolchain.env`](../../tools/toolchain.env) | Supplies the exact Pi package and toolchain pins consumed/asserted by Dev Container setup/smoke and the Sandbox launcher/bootstrap. |

## Documentation

| Need | Read |
| --- | --- |
| Package purpose and upgrade checks | [extensions.md](extensions.md) |
| Configuration consumers and runtime boundaries | [configuration.md](configuration.md) |
| Retained skill catalog and provenance | [skills.md](skills.md) |
| Planning, delegation, review, and verification | [workflows.md](workflows.md) and [delegation.md](delegation.md) |

Secrets and user preferences stay in user-level Pi configuration or environment variables. Project files contain no provider keys, model credentials, or trust decisions.

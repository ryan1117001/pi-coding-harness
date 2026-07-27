# Pi configuration

Tracked configuration describes the project package set, effective tools, and runtime boundaries. Pi installs the configured packages under ignored `.pi/npm/`; do not duplicate generated runtime files there.

| File | Consumer | Maintainer action |
| --- | --- | --- |
| [`.pi/settings.json`](../../.pi/settings.json) | Pi and installed extensions | List project packages and configure ReadSeek; it does not define subagent role profiles. |
| [`.pi/chains/`](../../.pi/chains/README.md) | `pi-subagents` | Store reusable generic chains and plan-specific chains in their documented namespaces. |
| [`.mcp.json`](../../.mcp.json) | MCP adapter | Define shared MCP servers. |
| [`compose.yml`](../../compose.yml) | Docker Compose | Define local service containers, ports, and Compose-only service wiring. |
| [`.env.example`](../../.env.example) | Local service operators | Provide safe local override examples. |
| [`../references/environment-variables.md`](../references/environment-variables.md) | Humans and agents | Explain runtime configuration, consumers, and defaults. |
| [`.pi/prompts/draft-plan.md`](../../.pi/prompts/draft-plan.md) | Parent agents | Describe the canonical draft, approval, registration, and explicit-execution lifecycle. |

## File tools

ReadSeek replaces the standard `read`, `edit`, `write`, and `grep` tool names. It uses anchored reads and edits, provides structural navigation, and validates syntax after source edits.

`syntaxValidation` is set to `warn`: a syntax finding is reported but does not itself block a write. Treat warnings as blockers until they are understood and resolved; use the repository's diagnostics checks before reporting completion.

## Delegation runtime

User-level Pi profile files under `~/.pi/agent/profiles/pi-subagents/` select the default subagent model and per-role model/fallback profiles. Those profiles are operational configuration, not workflow policy: inspect the active profile rather than duplicating model names in documentation. See [delegation.md](delegation.md) for role selection and single-writer rules.

## Permissions and cross-session work

The project loads a permission-system package, but this repository does not define its permission policy. Effective allow, ask, and deny rules may therefore come from user-level configuration. Do not claim a permission decision is guaranteed by this repository without inspecting the active runtime policy.

`pi-intercom` enables direct messages between Pi sessions on the same machine when the extension is loaded and enabled. Its local broker can start automatically; user-level configuration is optional unless it disables or changes the default behavior. Use it only to coordinate related work; it is not a replacement for the parent session's ownership of a delegated workflow.

See also: [extension inventory](extensions.md), [agent skills](skills.md), and [workflows](workflows.md).

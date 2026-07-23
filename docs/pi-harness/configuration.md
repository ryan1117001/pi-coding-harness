# Pi configuration

Tracked configuration makes the project harness reproducible. Package installation, effective tools, and runtime behavior are determined by the linked configuration files; do not duplicate generated runtime files under `.pi/npm/`.

| File | Consumer | Maintainer action |
| --- | --- | --- |
| [`.pi/settings.json`](../../.pi/settings.json) | Pi and installed extensions | Pin packages and configure ReadSeek and subagent defaults. |
| [`.pi/plannotator.json`](../../.pi/plannotator.json) | Plannotator | Keep non-trivial plans at their canonical `docs/prompts/` path. |
| [`.mcp.json`](../../.mcp.json) | MCP adapter | Define shared MCP servers. |
| [`compose.yml`](../../compose.yml) | Docker Compose | Define local service containers, ports, and Compose-only service wiring. |
| [`.env.example`](../../.env.example) | Local service operators | Provide safe local override examples. |
| [`../references/environment-variables.md`](../references/environment-variables.md) | Humans and agents | Explain runtime configuration, consumers, and defaults. |

## File tools

ReadSeek replaces the standard `read`, `edit`, `write`, and `grep` tool names. It uses anchored reads and edits, provides structural navigation, and validates syntax after source edits.

`syntaxValidation` is set to `warn`: a syntax finding is reported but does not itself block a write. Treat warnings as blockers until they are understood and resolved; use the repository's diagnostics checks before reporting completion.

## Delegation runtime

`settings.json` selects a default subagent model and per-role model/fallback profiles. Those profiles are operational configuration, not workflow policy: inspect the file rather than duplicating model names in documentation. See [delegation.md](delegation.md) for role selection and single-writer rules.

## Permissions and cross-session work

The project loads a permission-system package, but this repository does not define its permission policy. Effective allow, ask, and deny rules may therefore come from user-level configuration. Do not claim a permission decision is guaranteed by this repository without inspecting the active runtime policy.

`pi-intercom` enables direct messages between Pi sessions on the same machine when the extension is loaded and enabled. Its local broker can start automatically; user-level configuration is optional unless it disables or changes the default behavior. Use it only to coordinate related work; it is not a replacement for the parent session's ownership of a delegated workflow.

See also: [extension inventory](extensions.md), [agent skills](skills.md), and [workflows](workflows.md).

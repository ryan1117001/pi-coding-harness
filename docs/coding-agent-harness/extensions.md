# Pi extensions

Pi packages execute with the user's permissions. The package names below are the `packages` entries in [`.pi/settings.json`](../../.pi/settings.json). Effective package versions come from the installed runtime and are not documented here.

## Package inventory

| Package | Primary surface |
| --- | --- |
| `npm:pi-web-access` | Web search, source extraction, GitHub inspection, and video/PDF retrieval. |
| `npm:pi-readseek` | Anchored file reads and edits, structural navigation, and syntax validation. |
| `npm:pi-lens` | LSP diagnostics, read guards, structural checks, and project analysis. |
| `npm:pi-subagents` | Builtin delegation roles, orchestration, and worktree support. |
| `npm:pi-mcp-adapter` | Lazy MCP discovery through the shared [`.mcp.json`](../../.mcp.json). |
| `npm:pi-intercom` | Direct messages between related Pi sessions on the same machine. |
| `npm:@gotgenes/pi-permission-system` | Permission gates for tools, commands, MCP, skills, and file paths. |
| `npm:@narumitw/pi-retry` | Pi retry extension. |

Package-level licensing, bundled tools, and optional resources can change across releases. Review the package source and loaded runtime surface during an upgrade rather than treating this summary as a complete security inventory.

## Project configuration

- ReadSeek replaces the standard `read`, `edit`, `write`, and `grep` tool names. Its configured syntax-validation mode is `warn`, not write blocking.
- User-level Pi profile files under `~/.pi/agent/profiles/pi-subagents/` configure subagent model profiles. Model identifiers and fallbacks are operational settings, not project policy.
- The project declares one DaisyUI MCP server in [`.mcp.json`](../../.mcp.json) with `directTools: true`. Cached server tools register directly; a first run without cached metadata falls back to the MCP proxy while the cache populates.
- The permission-system package is installed, but a repository-level permission policy is not declared. User-level policy can affect the runtime decision.

See [configuration.md](configuration.md) for consumers and operational contracts, [delegation.md](delegation.md) for agent workflow, and [skills.md](skills.md) for skill provenance.

## Upgrade procedure

1. Read the package changelog, source, license, install scripts, and compatibility notes.
2. Install the candidate version in a disposable checkout.
3. Verify loaded tools, resources, prompts, skills, and effective permission behavior.
4. Run planning, subagent, MCP, file-tool, and diagnostics smoke checks relevant to the upgrade.
5. Update the package entry and this inventory in the same change.

Do not treat `pi update --extensions` as a source of project package configuration; the package list remains in [`.pi/settings.json`](../../.pi/settings.json).

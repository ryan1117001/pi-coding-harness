# Pi extensions

Pi packages execute with the user's permissions. The exact pins below are the `packages` entries in [`.pi/settings.json`](../../.pi/settings.json); upgrade one package at a time and run the relevant harness checks.

## Package inventory

| Package | Version | Primary surface |
| --- | --- | --- |
| [`pi-web-access`](https://github.com/nicobailon/pi-web-access) | 0.13.0 | Web search, source extraction, GitHub inspection, and video/PDF retrieval. |
| [`pi-readseek`](https://github.com/jarkkojs/readseek) | 0.8.0 | Anchored file reads and edits, structural navigation, and syntax validation. |
| [`pi-lens`](https://github.com/apmantza/pi-lens) | 3.8.71 | LSP diagnostics, read guards, structural checks, and project analysis. |
| [`pi-subagents`](https://github.com/nicobailon/pi-subagents) | 0.35.1 | Builtin delegation roles, orchestration, and worktree support. |
| [`pi-mcp-adapter`](https://github.com/nicobailon/pi-mcp-adapter) | 2.11.0 | Lazy MCP discovery through the shared [`.mcp.json`](../../.mcp.json). |
| [`pi-intercom`](https://github.com/nicobailon/pi-intercom) | 0.6.0 | Direct messages between related Pi sessions on the same machine. |
| [`@gotgenes/pi-permission-system`](https://github.com/gotgenes/pi-packages) | 20.10.0 | Permission gates for tools, commands, MCP, skills, and file paths. |

Package-level licensing, bundled tools, and optional resources can change across releases. Review the package source and loaded runtime surface during an upgrade rather than treating this summary as a complete security inventory.

## Project configuration

- ReadSeek replaces the standard `read`, `edit`, `write`, and `grep` tool names. Its configured syntax-validation mode is `warn`, not write blocking.
- The project configures subagent model profiles, but model identifiers and fallbacks remain authoritative only in [`settings.json`](../../.pi/settings.json).
- The project declares one DaisyUI MCP server in [`.mcp.json`](../../.mcp.json) with `directTools: true`. Cached server tools register directly; a first run without cached metadata falls back to the MCP proxy while the cache populates.
- The permission-system package is installed, but a repository-level permission policy is not declared. User-level policy can affect the runtime decision.

See [configuration.md](configuration.md) for consumers and operational contracts, [delegation.md](delegation.md) for agent workflow, and [skills.md](skills.md) for skill provenance.

## Upgrade procedure

1. Read the package changelog, source, license, install scripts, and compatibility notes.
2. Install the candidate version in a disposable checkout.
3. Verify loaded tools, resources, prompts, skills, and effective permission behavior.
4. Run planning, subagent, MCP, file-tool, and diagnostics smoke checks relevant to the upgrade.
5. Update the exact pin and this inventory in the same change.

Do not run `pi update --extensions` expecting pinned versions to move; pinned npm packages are intentionally skipped.

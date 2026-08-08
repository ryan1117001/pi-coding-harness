# Pi configuration

Tracked configuration describes the project package set, effective tools, and runtime boundaries. Pi installs the configured packages under ignored `.pi/npm/`; do not duplicate generated runtime files there.

| File | Consumer | Maintainer action |
| --- | --- | --- |
| [`.pi/settings.json`](../../.pi/settings.json) | Pi and installed extensions | List project packages and configure ReadSeek; it does not define subagent role profiles. |
| [`.pi/chains/`](../../.pi/chains/README.md) | `pi-subagents` | Store reusable generic chains and plan-specific chains in their documented namespaces. |
| [`.mcp.json`](../../.mcp.json) | MCP adapter | Define shared MCP servers. |
| [`compose.yml`](../../compose.yml) | Root Docker Compose | Define root service containers, PostgreSQL configuration, ports, and Compose-only application wiring. |
| [`.devcontainer/devcontainer.json`](../../.devcontainer/devcontainer.json) | VS Code and `@devcontainers/cli` | Select the Compose workspace service, startup set, non-root user, lifecycle setup, and forwarded ports. |
| [`.devcontainer/compose.yml`](../../.devcontainer/compose.yml) | Docker Compose through the Dev Container definition | Define the workspace bind mount, workspace-run API database DSN, and disposable dependency and cache volumes. |
| [`.devcontainer/setup.sh`](../../.devcontainer/setup.sh) | Dev Container `postCreateCommand` | Verify tools, install Pi, restore locked dependencies, and provision Chromium; it does not configure credentials or trust. |
| [`tools/toolchain.env`](../../tools/toolchain.env) | Dev Container setup/smoke and Sandbox launcher/bootstrap | Define the single repository-managed authority for the Pi package and every pinned toolchain version. |
| [`.env.example`](../../.env.example) | Local service operators | Provide safe local override examples. |
| [`../references/environment-variables.md`](../references/environment-variables.md) | Humans and agents | Explain runtime configuration, consumers, and defaults. |
| [`.pi/prompts/draft-plan.md`](../../.pi/prompts/draft-plan.md) | Parent agents | Describe the canonical draft, approval, registration, and explicit-execution lifecycle. |
| [`.sandbox/launch-pi.sh`](../../.sandbox/launch-pi.sh) | Manual Docker Sandbox users | Enforce exact `sbx` 0.38.0, create/attach/remove Sandboxes, select source mode, and configure the optional user Pi input. |

The Dev Container does not own PostgreSQL credentials: root [`compose.yml`](../../compose.yml) and a repo-root `.env` supply `POSTGRES_*`, while its Compose layer derives `DATABASE_URL` for API processes run in `workspace`. See [`.devcontainer/README.md`](../../.devcontainer/README.md) for operation, trust, and cache ownership.

The Sandbox launcher consumes `PI_USER_SETTINGS`, `PI_USER_EXTENSIONS`, `SANDBOX_STATE_ROOT`, `SANDBOX_BOOTSTRAP_NETWORK`, and `SANDBOX_SKIP_BROWSER`; its smoke helper consumes `SANDBOX_LIVE_SMOKE` and `SANDBOX_SMOKE_COMPOSE`. See the [Docker Sandbox Pi reference](../references/docker-sandbox-pi.md) for consumers, defaults, and trust limits.

## File tools

ReadSeek replaces the standard `read`, `edit`, `write`, and `grep` tool names. It uses anchored reads and edits, provides structural navigation, and validates syntax after source edits.

`syntaxValidation` is set to `warn`: a syntax finding is reported but does not itself block a write. Treat warnings as blockers until they are understood and resolved; use the repository's diagnostics checks before reporting completion.

## Delegation runtime

User-level Pi profile files under `~/.pi/agent/profiles/pi-subagents/` select the default subagent model and per-role model/fallback profiles. Those profiles are operational configuration, not workflow policy: inspect the active profile rather than duplicating model names in documentation. See [delegation.md](delegation.md) for role selection and single-writer rules.

## Permissions and cross-session work

The project loads a permission-system package, but this repository does not define its permission policy. Effective allow, ask, and deny rules may therefore come from user-level configuration. Do not claim a permission decision is guaranteed by this repository without inspecting the active runtime policy.

`pi-intercom` enables direct messages between Pi sessions on the same machine when the extension is loaded and enabled. Its local broker can start automatically; user-level configuration is optional unless it disables or changes the default behavior. Use it only to coordinate related work; it is not a replacement for the parent session's ownership of a delegated workflow.

See also: [extension inventory](extensions.md), [agent skills](skills.md), and [workflows](workflows.md).

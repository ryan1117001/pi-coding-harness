---
status: approved
---

# Add opt-in host Pi extensions to the Dev Container

## Goal

Add an explicit opt-in that makes a trusted developer's user-level Pi extensions and global package declarations available inside the trusted Dev Container. Keep the default editor, headless, and CI paths independent of host Pi state, install package-managed extensions into Linux-native container volumes, and continue supplying model/provider credentials only through explicitly forwarded environment variables.

## Context

- Pi discovers direct global extensions under `~/.pi/agent/extensions` and global package declarations from `~/.pi/agent/settings.json`.
- The Dev Container currently exposes neither host path. It provides project-level Pi settings through the source bind and stores project package installations under named `.pi/npm` and `.pi/git` volumes.
- Mounting host `~/.pi/agent/npm` or `git` into Linux can import macOS-native dependencies and is not acceptable.
- Pi stores API keys and OAuth credentials in `~/.pi/agent/auth.json`. A writable single-file bind would not share Pi's sibling lock between host and container processes, creating a credential race. A read-only bind also fails when OAuth refresh needs to write.
- Pi 0.83.0 can migrate a legacy top-level `apiKeys` object from global settings into local `auth.json`; the opt-in must reject that key structurally without printing values.
- The approved Dev Container baseline requires credentials to remain ephemeral and forbids baking, committing, or persisting them in cache volumes.

## Workflow

The matching plan-specific [saved chain](../../../.pi/chains/saved-plans/2026_08_06_1521-opt-in-host-pi-extensions.chain.json) performs read-only context collection, serial implementation and documentation, parallel security and reproducibility review, one serial fix pass, and final validation. It must not run until this plan has explicit user approval and is registered in the plan index.

This is a configuration and documentation behavior change, so the repository's TDD exception applies. Add synthetic configuration-contract tests before finalizing the implementation; no real credentials or provider calls may be used.

## Decisions and non-goals

### Decisions

- Preserve the default Dev Container behavior when the integration is not selected. CI must continue to build and run without `~/.pi` on the host.
- Add one validated wrapper for VS Code and headless commands. The wrapper opts into an additional Compose layer through Dev Container local-environment substitution.
- Require host `~/.pi/agent/extensions` to be a readable directory and `settings.json` to be a readable regular file. Reject missing paths and any top-level legacy `apiKeys` field before Docker runs, without printing settings values, and never create host paths implicitly.
- Bind only `extensions/` and `settings.json`, both read-only. Do not bind the complete host agent directory.
- Add container-owned named volumes at `/home/vscode/.pi/agent/npm` and `/home/vscode/.pi/agent/git` for Linux-native global package installations. Preserve the existing project-level package volumes.
- Do not mount `auth.json` in any mode. Continue forwarding only the required API-key environment variables per command or runner. OAuth subscription sharing is not supported by this integration.
- Treat mounted settings and extensions as trusted executable/configuration input. Document that settings may contain commands, secret literals, or host-only paths; reject the known legacy `apiKeys` migration field; and state that extensions execute with container-user and host-Docker authority.
- Keep activation explicit and reversible. Relaunching without the wrapper restores the default host-state-free configuration after recreating the workspace container.

### Non-goals

- Do not share, copy, or persist the primary host Pi auth file.
- Do not add a container-specific OAuth login or persistent credential store.
- Do not mount host Pi sessions, trust decisions, models cache, prompts, skills, themes, npm packages, Git checkouts, or the whole agent directory.
- Do not automatically translate host-absolute settings paths or repair extensions with macOS-native nested dependencies.
- Do not change project-level `.pi/settings.json` package ownership or the existing Docker-outside-of-Docker trust decision.

## Files to add or modify

| Path | Change |
| --- | --- |
| `.devcontainer/devcontainer.json` | Add a host-environment-selected optional Compose layer with a checked-in no-op default. |
| `.devcontainer/compose.host-pi-disabled.yml` | Provide the valid no-op layer used by default and in CI. |
| `.devcontainer/compose.host-pi.yml` | Bind host extensions and global settings read-only with host-path creation disabled. |
| `.devcontainer/with-host-pi.sh` | Validate host paths, export only activation variables, and execute VS Code or headless commands without reading credential contents. |
| `.devcontainer/test-host-pi.sh` | Test disabled and enabled configuration using disposable non-secret fixtures. |
| `.devcontainer/compose.yml` | Add Linux-native global Pi npm and Git named volumes. |
| `.devcontainer/setup.sh` | Prepare the global package-volume paths for the non-root user. |
| `.devcontainer/smoke-test.sh` | Verify global and project package roots remain writable and separated without assuming host integration is enabled. |
| `.github/workflows/devcontainer.yml` | Run the synthetic host-Pi configuration contract before the unchanged credential-free build/up/smoke path. |
| `.devcontainer/README.md` | Document activation, environment credential forwarding, compatibility limits, trust, reset, and rollback. |
| `AGENTS.md` | State the opt-in host extension/settings trust boundary and retain ephemeral credential policy. |
| `docs/design-docs/0001-devcontainer-workspace.md` | Extend the existing decision with the optional host Pi input and rejected auth-sharing alternatives. |
| `docs/ARCHITECTURE.md` | Record optional read-only host configuration inputs and container-owned global package state. |

## Steps

- [x] **1. Define the opt-in configuration contract.**
  - Add a synthetic host-state test using temporary extension and settings fixtures with no secrets, plus a forbidden legacy `apiKeys` fixture containing only a dummy marker.
  - Verify the default configuration resolves without host Pi state.
  - Verify enabled mounts have the exact sources, targets, and read-only modes; no mount may target `auth.json` or source host `npm`/`git`.
  - Verify the wrapper rejects missing or invalid paths and the forbidden `apiKeys` structure before Docker, never prints values, and leaves no fixture state behind.
  - Acceptance: tests cover default, enabled configuration/runtime, invalid paths, and forbidden credential migration without real credentials or provider traffic.

- [x] **2. Add safe editor and headless activation.**
  - Add a checked-in no-op Compose layer and an enabled host-Pi layer selected through a validated local-environment variable.
  - Bind `extensions/` and `settings.json` only, read-only, with host-path creation disabled.
  - Add a wrapper that canonicalizes paths, structurally rejects legacy credential migration fields without displaying settings, exports the layer and host-agent directory, then executes the supplied `code` or `devcontainer` command.
  - Acceptance: ordinary commands remain unchanged; wrapped VS Code and CLI configuration resolve the same explicit mounts; missing paths fail without creation.

- [x] **3. Provide Linux-native global package storage.**
  - Add named volumes for `/home/vscode/.pi/agent/npm` and `/home/vscode/.pi/agent/git` and prepare ownership idempotently.
  - Preserve project volumes at `/workspaces/workspace/.pi/npm` and `/workspaces/workspace/.pi/git`.
  - Extend smoke checks to prove both scopes are writable and distinct.
  - Acceptance: mounted global package declarations install only into container-owned Linux storage, while project packages retain their current storage.

- [x] **4. Preserve the credential boundary.**
  - Do not add an auth mount, auth volume, login step, or credential copy.
  - Keep headless API-key forwarding explicit and per-command; ensure tests and CI provide no provider credentials.
  - Inspect resolved configuration, image context, and repository diff for auth paths or credential material; prove a legacy `apiKeys` settings object is rejected before Pi starts.
  - Acceptance: `auth.json` is absent from all configured mounts and volumes, and default/opted-in smoke requires no provider credential.

- [x] **5. Document trust, compatibility, operation, and rollback.**
  - Document wrapper commands for a freshly launched VS Code process and for `read-configuration`, `build`, `up`, `exec`, and teardown.
  - Explain that global settings are read-only, package code installs into disposable Linux volumes, and host settings/extensions may still be incompatible or contain sensitive/executable input.
  - State that environment credentials are visible to trusted same-user processes for the invoked command and that OAuth auth sharing is unsupported.
  - Document rollback by stopping/recreating the opted-in workspace without the wrapper and optionally removing only the new global package volumes.
  - Acceptance: architecture, design, agent policy, and operational guidance agree and make no sandbox or OAuth-sharing claim.

- [x] **6. Complete implementation validation and independent review.**
  - Run shell syntax, synthetic contract tests, default and fixture-enabled configuration resolution, fixture-enabled up/runtime mount checks and teardown, frozen default Dev Container build/up/smoke, merged Compose checks, Markdown/link checks, affected Nx lint/tests, and `git diff --check`.
  - Confirm default CI remains host-state-free and opted-in runtime testing uses only disposable fixtures.
  - Run independent security and reproducibility reviews and apply only in-scope blocker fixes serially.
  - Acceptance: required checks pass, reviewers report no blockers, no generated fixture/auth material remains, and the verified platform matrix is stated accurately.

## Verification

```bash
bash -n \
  .devcontainer/setup.sh \
  .devcontainer/smoke-test.sh \
  .devcontainer/with-host-pi.sh \
  .devcontainer/test-host-pi.sh
.devcontainer/test-host-pi.sh
.devcontainer/test-host-pi.sh --runtime

pnpm exec devcontainer read-configuration \
  --workspace-folder . \
  --include-merged-configuration
.devcontainer/with-host-pi.sh \
  pnpm exec devcontainer read-configuration \
  --workspace-folder . \
  --include-merged-configuration

pnpm exec devcontainer build --workspace-folder . --frozen-lockfile
pnpm exec devcontainer up --workspace-folder . --frozen-lockfile
pnpm exec devcontainer exec --workspace-folder . \
  bash -lc '.devcontainer/setup.sh && .devcontainer/smoke-test.sh'
pnpm exec devcontainer exec --workspace-folder . \
  bash -lc 'NX_SKIP_NX_CACHE=true pnpm exec nx affected -t lint test --base=origin/main --parallel=3'

pnpm exec markdownlint-cli2 \
  AGENTS.md \
  .devcontainer/README.md \
  docs/ARCHITECTURE.md \
  docs/design-docs/0001-devcontainer-workspace.md \
  docs/prompts/2026_08_06_1521-opt-in-host-pi-extensions/README.md
git diff --check
git status --short
```

The enabled configuration tests use a disposable fake host-agent directory. A manual real-host check may confirm that trusted extensions and package declarations load, but it must not print settings contents, forward credentials, call a provider, or mutate the host settings/extensions.

## Documentation impact

This changes developer and agent startup, optional host inputs, Pi package storage, and the security model. Update the existing Dev Container guide, architecture description, design decision, and root agent policy in the same change. No application network or browser-to-API architecture changes.

## Risks and recovery

- **Trusted code execution:** global extensions and package declarations can execute code with workspace and host-Docker authority. Disable the integration by recreating the workspace without the wrapper.
- **Sensitive settings:** global settings may contain literal secrets or credential commands. Users must inspect the file before opting in; the repository cannot sanitize arbitrary settings.
- **Concurrent settings changes:** the read-only settings bind does not share Pi's sibling settings lock with host processes. Do not run host `pi config` or otherwise rewrite global settings while an opted-in workspace is starting or running; stop/recreate and retry if the file changes.
- **Platform incompatibility:** raw extensions may include macOS-native nested dependencies or absolute paths. Convert them to package declarations or maintain Linux-compatible source when needed.
- **Persistent executable caches:** global npm/Git volumes contain executable package code but no intentional credentials. Remove the new volumes during a sensitive reset and restore from settings later.
- **VS Code environment reuse:** an existing VS Code process may not inherit wrapper variables. Fully quit VS Code before launching through the wrapper.
- **Missing-path bypass:** Compose rejects missing bind sources only when creating the container, so wrapper preflight remains the primary user-facing validation.

## Assumptions requiring approval

- User-level `extensions/` and the complete global `settings.json` may be exposed read-only to the trusted container.
- Global package declarations may install executable Linux copies into disposable named volumes.
- API keys continue to be forwarded explicitly through environment variables; host `auth.json` and OAuth subscription auth remain unavailable.
- Users accept the existing host-Docker authority and inspect global settings/extensions before opting in.

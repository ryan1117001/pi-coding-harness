# Dev Container workspace

This definition provides a Compose-backed development workspace for trusted humans and trusted coding agents. It is an alternative to, not a replacement for, the host workflow in [`../CONTRIBUTING.md`](../CONTRIBUTING.md).

The optional [Docker Sandbox Pi runtime](../docs/references/docker-sandbox-pi.md) is separate from this trusted workspace. It uses a Sandbox VM and does not give the Sandbox host-Docker authority; it does not replace host or Dev Container development.

## Prerequisites

- **VS Code workflow:** Docker must be available to VS Code, and VS Code must have the Dev Containers extension installed. The repository recommends the extension in [`../.vscode/extensions.json`](../.vscode/extensions.json).
- **Headless workflow:** Docker and `@devcontainers/cli` 0.88.0 must be available to the host user. The commands below use a preinstalled `devcontainer` executable. The CLI is pinned in the root [`package.json`](../package.json), so `corepack enable && pnpm install --frozen-lockfile` followed by `pnpm exec devcontainer` is the repository-managed bootstrap when Node and Corepack are already available. The container supplies the repository's Node, pnpm, Python, uv, Pi, and browser development toolchain after it starts.

The checked-in configuration runs only `workspace` and `postgres`. It does not start the root `api` or `web` Compose services. Dev Container lifecycle commands and interactive sessions run as the non-root `vscode` user; root-owned initialization processes prepare Docker socket access before the workspace is ready. Host Pi settings and extensions are disabled unless the explicit opt-in procedure below selects their Compose layer.

## Start

### VS Code

Open the repository in VS Code and select **Dev Containers: Reopen in Container**. Closing the Dev Container uses the configured `stopCompose` action, which stops the Compose application. Do not close it while another service in this Compose application must remain running.

The definition forwards port 4200 for a workspace-run web server and port 8000 for a workspace-run API server. Start either server in the integrated terminal:

```bash
pnpm exec nx serve api
pnpm exec nx serve web
```

### Headless

Run the commands from the repository root:

```bash
devcontainer read-configuration --workspace-folder . --include-merged-configuration
devcontainer up --workspace-folder . --frozen-lockfile
devcontainer exec --workspace-folder . bash -lc '.devcontainer/smoke-test.sh'
```

The `up` lifecycle invokes [`.devcontainer/setup.sh`](setup.sh). To rerun setup after an interrupted install, run:

```bash
devcontainer exec --workspace-folder . bash -lc '.devcontainer/setup.sh'
```

### Interactive terminal and Pi

Start the default Dev Container and open an interactive login shell from a host terminal:

```bash
pnpm exec devcontainer up --workspace-folder . --frozen-lockfile
pnpm exec devcontainer exec --workspace-folder . bash -l
```

The shell runs as `vscode` in `/workspaces/workspace`. Run `pi`, Nx commands, tests, or other development tools there. Exit the shell with `exit`; this returns to the host without stopping the container.

To launch Pi directly without first opening a shell:

```bash
pnpm exec devcontainer exec --workspace-folder . pi
```

When using the user-level Pi extension opt-in, create the ignored local wrapper from the tracked example once:

```bash
cp .devcontainer/with-host-pi.example.sh .devcontainer/with-host-pi.sh
chmod +x .devcontainer/with-host-pi.sh
```

Set `NODE_EXTRA_CA_CERTS` to an absolute path before invoking the wrapper, or customize the ignored local copy with a machine-specific default. Run the local wrapper for both startup and terminal attachment so every command resolves the same Compose layer:

```bash
.devcontainer/with-host-pi.sh pnpm exec devcontainer up \
  --workspace-folder . \
  --frozen-lockfile
.devcontainer/with-host-pi.sh pnpm exec devcontainer exec \
  --workspace-folder . \
  bash -l
```

The wrapper mounts the host CA certificate named by `NODE_EXTRA_CA_CERTS` read-only at the same absolute path and forwards that variable into the workspace. The tracked example has no machine-specific certificate default.

Inside that shell, `pi` loads the mounted read-only user settings and extensions. Provider authentication is still environment-only. To start Pi directly with an ephemeral API key:

```bash
export ANTHROPIC_API_KEY='runner-provided-value'
.devcontainer/with-host-pi.sh pnpm exec devcontainer exec \
  --workspace-folder . \
  --remote-env "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" \
  pi
unset ANTHROPIC_API_KEY
```

Use a masked, short-lived secret rather than a shell literal in automation. See [Trust and credentials](#trust-and-credentials) for the exposure boundary.

The recorded validation covers the headless configuration, build, `up`, repeated setup, and smoke commands. It directly runs on Docker Desktop for macOS arm64. The template ships no CI workflows, so this validation and [`test-host-pi.sh`](test-host-pi.sh) are run by hand. An editor attachment session is not separately recorded. Do not infer support for other platforms or architectures from this definition.

## Opt in to user-level Pi extensions

The default definition does not expose user-level Pi state. The opt-in mounts `~/.pi/agent/extensions`, `~/.pi/agent/settings.json`, and the configured `NODE_EXTRA_CA_CERTS` file into the container read-only. It does not mount `auth.json`, sessions, trust decisions, models, prompts, skills, themes, `npm`, or `git`.

Before opting in, inspect the complete global `settings.json` and the CA certificate. These files are available to trusted container processes. The settings file can contain commands, literal values, host-only paths, and package declarations; the CA certificate extends Node's TLS trust. The wrapper requires readable, non-symlink settings, extensions, and CA certificate inputs. It rejects a top-level legacy `apiKeys` field before Docker runs without displaying its values. Do not change global settings while an opted-in workspace runs: Pi's host and container settings locks are separate. Stop and recreate the workspace, then retry after the host edit completes.

Stop and remove an existing default workspace container before changing the Compose layer. Run this from the repository root:

```bash
localWorkspaceFolder="$PWD" docker compose \
  -f compose.yml \
  -f .devcontainer/compose.yml \
  rm --stop --force workspace
```

### VS Code with host Pi

Fully quit VS Code before launch so the application receives the wrapper environment. Then run:

```bash
.devcontainer/with-host-pi.sh code .
```

In the newly launched window, select **Dev Containers: Reopen in Container**. A running VS Code process can reuse its prior environment and omit the opt-in layer.

### Headless with host Pi

Run the wrapper before every Dev Container CLI command that reads the definition:

```bash
.devcontainer/with-host-pi.sh pnpm exec devcontainer read-configuration \
  --workspace-folder . \
  --include-merged-configuration
.devcontainer/with-host-pi.sh pnpm exec devcontainer build \
  --workspace-folder . \
  --frozen-lockfile
.devcontainer/with-host-pi.sh pnpm exec devcontainer up \
  --workspace-folder . \
  --frozen-lockfile
.devcontainer/with-host-pi.sh pnpm exec devcontainer exec \
  --workspace-folder . \
  bash -lc '.devcontainer/smoke-test.sh'
```

Global package declarations in the mounted settings install into the container-owned Linux volumes at `/home/vscode/.pi/agent/npm` and `/home/vscode/.pi/agent/git`. Project package declarations remain in the separate `/workspaces/workspace/.pi/npm` and `/workspaces/workspace/.pi/git` volumes. Do not mount the host package trees: they can contain host-platform dependencies. Source-mounted extensions with host-only paths or nested host-platform dependencies can also fail in Linux.

Use the existing explicit environment-variable forwarding procedure for provider credentials. OAuth subscription authentication and primary host `auth.json` sharing are unsupported by this opt-in.

## Topology and configuration

[`../compose.yml`](../compose.yml) owns the PostgreSQL service and its `POSTGRES_*` configuration. [`.devcontainer/compose.yml`](compose.yml) adds `workspace`, waits for healthy `postgres`, and sets the workspace-run API's `DATABASE_URL` to the Compose host `postgres`. The workspace is a source bind mount. Linux-specific dependencies and reusable state use named volumes: project `node_modules`, the API virtual environment, pnpm and uv caches, Playwright browsers, Nx state, global Pi package/worktree state, and project Pi package/worktree state.

| Configuration                                                  | Consumer                                                                                       | Ownership                                                                                                                           |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| [`devcontainer.json`](devcontainer.json)                       | VS Code and `@devcontainers/cli`                                                               | Selects the workspace service, startup set, user, lifecycle hook, forwarded ports, and the default or opt-in host Pi Compose layer. |
| [`compose.yml`](compose.yml)                                   | Docker Compose, through the Dev Container definition                                           | Defines the workspace bind mount, workspace environment, dependency volumes, and PostgreSQL dependency.                             |
| [`compose.host-pi-disabled.yml`](compose.host-pi-disabled.yml) | VS Code and `@devcontainers/cli` when no opt-in is selected                                    | Supplies the default no-op host Pi Compose layer.                                                                                   |
| [`compose.host-pi.yml`](compose.host-pi.yml)                   | Docker Compose through the Dev Container definition when selected by the local host Pi wrapper | Binds the validated host settings, extensions, and CA certificate read-only; forwards `NODE_EXTRA_CA_CERTS`.                        |
| [`with-host-pi.example.sh`](with-host-pi.example.sh)           | Template for the ignored local `with-host-pi.sh` launcher                                      | Validates the host Pi and CA certificate inputs and selects the opt-in Compose layer without committing machine-specific paths.     |
| [`Dockerfile`](Dockerfile)                                     | Dev Container image build                                                                      | Provides the pinned base tools and image-level packages.                                                                            |
| [`setup.sh`](setup.sh)                                         | Dev Container `postCreateCommand` and manual recovery                                          | Verifies tool versions, restores locked dependencies, installs Pi, and installs Chromium.                                           |
| [`../compose.yml`](../compose.yml)                             | Root Docker Compose                                                                            | Defines PostgreSQL data, credentials, and the root `api` and `web` services.                                                        |

### Version authority

| Input                                         | Authority                                                                                                                      | Update contract                                                                                                                                                                                      |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Node 24.19.0                                  | Digest-pinned Node image in [`Dockerfile`](Dockerfile)                                                                         | Update the image digest and [`../tools/toolchain.env`](../tools/toolchain.env) together; `setup.sh` and `smoke-test.sh` derive their assertions from it.                                             |
| pnpm 11.20.0                                  | Root [`package.json`](../package.json) `packageManager`                                                                        | Mirror the same version in [`../tools/toolchain.env`](../tools/toolchain.env), the Dev Container Dockerfile, and the web Dockerfile.                                                                 |
| Python 3.14.4                                 | Python Feature option in [`devcontainer.json`](devcontainer.json)                                                              | Regenerate `devcontainer-lock.json` and update [`../tools/toolchain.env`](../tools/toolchain.env); keep the API image pin synchronized.                                                              |
| uv 0.12.2                                     | Digest-pinned uv image in [`Dockerfile`](Dockerfile)                                                                           | Update the digest and [`../tools/toolchain.env`](../tools/toolchain.env) together.                                                                                                                   |
| Pi 0.84.1                                     | `PI_PACKAGE` in [`../tools/toolchain.env`](../tools/toolchain.env)                                                             | Update the package string only; every consumer derives the version from it.                                                                                                                          |
| Dev Container Features                        | [`devcontainer.json`](devcontainer.json) options plus generated [`devcontainer-lock.json`](devcontainer-lock.json) digests     | Regenerate the lock with `@devcontainers/cli@0.88.0`; never hand-edit Feature resolutions.                                                                                                           |
| Dev Container CLI 0.88.0                      | Root [`package.json`](../package.json), `pnpm-lock.yaml`, and this guide                                                       | Update the exact dependency, lockfile, and headless commands in the same change.                                                                                                                     |
| Docker CLI 29.6.1                             | Docker-outside-of-Docker Feature option                                                                                        | Regenerate the Feature lock and re-run headless smoke. Compose and Buildx plugins come from the locked Feature's upstream package installation and are validated, but are not exact repository pins. |
| Base images                                   | Immutable manifest digests in [`Dockerfile`](Dockerfile)                                                                       | Verify the reviewed digest's platform manifest before replacement.                                                                                                                                   |
| JavaScript/Python dependencies and Playwright | `pnpm-lock.yaml` and `projects/api/uv.lock`                                                                                    | Restore only with frozen/locked commands; browser binaries follow the locked Playwright package.                                                                                                     |

See [`../docs/references/environment-variables.md`](../docs/references/environment-variables.md) for the `POSTGRES_*` and `DATABASE_URL` consumers and defaults.

## Trust and credentials

Docker-outside-of-Docker exposes the host Docker daemon to the workspace. A process in this container can control that daemon. Use this definition only for trusted humans and trusted coding agents; it is not a sandbox for untrusted code or agents.

The definition does not store provider keys, Git or SSH credentials, or Pi profiles in the image or named volumes. Do not add them to the repository, image, or cache volumes. The optional host Pi layer exposes only read-only settings and extensions, but those files are still trusted input available to workspace processes with host-Docker authority. Pi trust and project package configuration remain governed by [`.pi/settings.json`](../.pi/settings.json) and the guidance in [`../docs/coding-agent-harness/README.md`](../docs/coding-agent-harness/README.md).

Headless runners must forward each required environment variable explicitly; host variables are not inherited automatically. For example:

```bash
export ANTHROPIC_API_KEY='runner-provided-value'
devcontainer exec --workspace-folder . \
  --remote-env "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" \
  bash -lc 'command-that-needs-the-key'
unset ANTHROPIC_API_KEY
```

Use a runner's masked, short-lived secret rather than a shell literal in real automation. The value exists in the target process environment and may be visible to same-user processes for that command; unset it in the runner after use. Prefer forwarded SSH agents or credential helpers for Git. Never embed credentials in package URLs or global settings: Git can retain a credential-bearing origin URL in the persistent global worktree volume. Do not copy private keys or Pi auth files into the workspace.

## Browsers

Setup installs Chromium and its system dependencies. Chromium supports the default browser-dependent checks. Install the complete Playwright browser set only when running the cross-browser suite:

```bash
sudo env "PATH=$PATH" pnpm exec playwright install-deps
pnpm exec playwright install
```

## Reset and teardown

Named volumes make dependencies and caches disposable. Do not reset them while the workspace container exists. From the host, remove only the workspace container before deleting its cache volumes; this preserves the `postgres` container and `postgres-data` volume:

```bash
localWorkspaceFolder="$PWD" docker compose -f compose.yml -f .devcontainer/compose.yml \
  rm --stop --force workspace

docker volume rm \
  workspace_workspace-node-modules \
  workspace_web-node-modules \
  workspace_web-e2e-node-modules \
  workspace_api-node-modules \
  workspace_postgres-node-modules \
  workspace_api-venv \
  workspace_pnpm-store \
  workspace_uv-cache \
  workspace_playwright-browsers \
  workspace_nx-state \
  workspace_pi-global-packages \
  workspace_pi-global-worktrees \
  workspace_pi-packages \
  workspace_pi-worktrees
```

Start the container again with the headless `up` command or VS Code; setup restores dependencies from the lockfiles.

To stop using the host Pi opt-in, remove the opted-in workspace container with its selected layer, then start the default definition without the wrapper:

```bash
localWorkspaceFolder="$PWD" docker compose \
  -f compose.yml \
  -f .devcontainer/compose.yml \
  rm --stop --force workspace
pnpm exec devcontainer up --workspace-folder . --frozen-lockfile
```

The host settings and extensions remain unchanged because their binds are read-only. Remove `workspace_pi-global-packages` and `workspace_pi-global-worktrees` with the reset command above when the downloaded global package state must be discarded.

For a non-destructive end to a headless run, stop only the workspace from the host. Stop `postgres` separately only when no root Compose or Dev Container user shares it:

```bash
localWorkspaceFolder="$PWD" docker compose -f compose.yml -f .devcontainer/compose.yml stop workspace
# Optional when this runner exclusively owns PostgreSQL:
localWorkspaceFolder="$PWD" docker compose -f compose.yml -f .devcontainer/compose.yml stop postgres
```

For intentional full teardown, run this host command only after confirming that no root Compose service must remain running. It stops the shared Compose application and removes all of its volumes, including PostgreSQL data:

```bash
localWorkspaceFolder="$PWD" docker compose -f compose.yml -f .devcontainer/compose.yml down --volumes --remove-orphans
```

# 0001: Compose-backed Dev Container workspace

## Context

The repository supports host development through pnpm, uv, Pi, and root Docker Compose. It also provides a Dev Container for trusted users who need a repository development environment without installing the workspace runtimes on the host.

The root [`compose.yml`](../../compose.yml) owns PostgreSQL and the root API and web service images. The Dev Container needs PostgreSQL but does not need to change those application-service contracts.

## Decision

The Dev Container layers [`.devcontainer/compose.yml`](../../.devcontainer/compose.yml) after the root Compose file. The layer adds a non-root `workspace` service and starts only `workspace` and healthy `postgres`. API and web development servers run with Nx inside `workspace`.

The workspace-run API uses `DATABASE_URL` with the Compose DNS host `postgres`. The source checkout is bind-mounted. Dependency trees, the API virtual environment, caches, browser binaries, Nx state, and Pi runtime state use named volumes.

The workspace has Docker-outside-of-Docker access. This grants host-daemon authority to processes in the workspace and is limited to trusted humans and trusted coding agents. It is not a sandbox. Credentials remain outside images and volumes and are supplied ephemerally when needed.

The default workspace does not expose user-level Pi state. An explicit opt-in binds only the host user's `~/.pi/agent/extensions` directory and `settings.json` file read-only. The container stores global Pi package downloads and Git package checkouts in its own Linux named volumes, separate from the project's Pi runtime volumes. The opt-in does not expose `auth.json`, sessions, trust decisions, model cache, host Pi package trees, or the whole agent directory. OAuth sharing is unsupported.

## Consequences

- Host development and the root Compose workflow remain supported.
- The Dev Container supplies its pinned tools through the container lifecycle and does not automatically start application servers.
- PostgreSQL starts for the Dev Container. Its root `postgres-data` volume remains separate from disposable workspace dependency and cache volumes.
- Chromium is installed by default. Firefox and WebKit remain explicit Playwright installations.
- Opting in makes the complete global Pi settings file and extensions available to trusted workspace processes. Settings can contain executable commands, sensitive literals, and host-only paths; the wrapper rejects the legacy top-level `apiKeys` migration field but does not sanitize other settings. Do not rewrite global settings while an opted-in workspace runs because host and container settings locks are separate.
- Host package trees are not portable to the Linux workspace. Global package declarations install into disposable container volumes; extensions with host-platform dependencies or host-only paths can fail.
- The fixed root Compose application name applies to this layered configuration; concurrent clones or worktrees are not covered by this definition.
- The documented direct validation is Docker Desktop for macOS arm64. The repository does not claim additional platform or architecture support without evidence.

## Alternatives considered

- **Reuse the root `web` service:** it does not provide the Python and agent tooling required by the workspace.
- **Reuse the root `api` service:** it is a production-oriented API runtime rather than a general development shell.
- **Docker-in-Docker:** it uses a separate daemon instead of the host daemon and does not preserve the existing host Compose workflow.
- **No Docker access:** it prevents container-based Compose and Docker workflows in the workspace.
- **Separate human and agent definitions:** it duplicates setup and topology. The repository instead limits one full-capability definition to the trusted audience.
- **Share host Pi authentication:** a writable single-file `auth.json` bind does not share Pi's sibling lock between host and container processes, while a read-only bind cannot support OAuth refresh. The definition instead supports only explicit environment credentials.

See [`.devcontainer/README.md`](../../.devcontainer/README.md) for operation and teardown, and [`../ARCHITECTURE.md`](../ARCHITECTURE.md) for the resulting topology.

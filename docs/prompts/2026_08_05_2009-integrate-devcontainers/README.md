---
status: approved
---

# Integrate Docker Dev Containers for humans and agents

## Goal

Add one reproducible, Compose-backed Dev Container that trusted human developers and trusted coding agents can use through VS Code or the headless `devcontainer` CLI. The environment provides the repository's Node, pnpm, Python, uv, Pi, PostgreSQL, Docker Compose, and Chromium workflows without requiring those development runtimes on the host.

## Context

- `.devcontainer/` is empty and untracked, so the repository has no Dev Container contract.
- The root [`compose.yml`](../../../compose.yml) already owns the `postgres`, `api`, and `web` services. Neither application image is a suitable general development shell: the web image is Node-only and the API image is a production-oriented non-root runtime.
- [`package.json`](../../../package.json) pins pnpm 11.15.1, while [`projects/web/Dockerfile`](../../../projects/web/Dockerfile) activates pnpm 11.9.0 despite claiming to match the workspace pin.
- Current onboarding in [`README.md`](../../../README.md) and [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) is host-first. Pi itself is user-installed, while tracked [`.pi/settings.json`](../../../.pi/settings.json) configures project extensions and generated runtime state under ignored paths.
- Docker-outside-of-Docker preserves the existing Compose workflow, but access to the host Docker socket grants host-daemon authority. A non-root container user does not make that socket a sandbox.
- Official Dev Container guidance supports Compose layering, non-root UID/GID adjustment, locked Features, lifecycle hooks, and headless CLI operation. Docker and Astral guidance requires secrets to stay out of image layers and recommends locked dependency installs and pinned uv inputs.

## Workflow

The matching plan-specific [saved chain](../../../.pi/chains/saved-plans/2026_08_05_2009-integrate-devcontainers.chain.json) performs read-only context collection, serial implementation and documentation, parallel independent review, one serial fix pass, and final validation. It must not run until this plan has explicit user approval and is registered in the plan index.

This is configuration, infrastructure, and documentation work, so the repository's TDD exception applies. Preserve a RED baseline by showing that `devcontainer read-configuration` or `devcontainer build` cannot find a definition before implementation, then use headless build and smoke checks as the behavioral contract.

## Decisions and non-goals

### Decisions

- Add a dedicated `workspace` service only in `.devcontainer/compose.yml`; layer it after the root Compose file from `devcontainer.json` rather than changing the application-service contract.
- Start `workspace` and healthy `postgres` by default. Run web and API through Nx inside the workspace; do not automatically start the root `web` and `api` service images.
- Connect workspace-run API processes to `postgres` through the existing Compose DNS name and local-development credentials.
- Run lifecycle hooks and shells as a non-root `vscode` user with host UID/GID adjustment.
- Align the environment to Node 24, pnpm 11.15.1, Python 3.14, uv 0.11.14, and `@earendil-works/pi-coding-agent` 0.83.0. Pin exact inputs where supported, generate and commit the Dev Container Feature lock with a pinned CLI, and document the authority for every version.
- Bind-mount source while isolating Linux-specific dependencies and caches with named volumes. Caches remain disposable and reproducible from `pnpm-lock.yaml` and `projects/api/uv.lock`.
- Install Chromium and its system dependencies by default. Keep Firefox and WebKit installation explicit for the full `web-e2e` matrix.
- Make Docker-outside-of-Docker available only for trusted humans and trusted agents. Inject credentials ephemerally through environment variables, forwarded agents, or runner-provided secret files; never bake, commit, or persist credentials in cache volumes.
- Keep editor extensions optional. Setup, smoke checks, and normal commands must work without a TTY or editor attachment.

### Non-goals

- Do not present the Dev Container as isolation for untrusted agents or untrusted repository code.
- Do not replace the host development path, production/application Dockerfiles, or root Compose workflow.
- Do not redesign browser-to-API behavior or introduce a new application network dependency.
- Do not bake dependency trees, Pi profiles, provider keys, Git/SSH credentials, or project runtime artifacts into the image.
- Do not install every Playwright browser during default setup.
- Do not add custom Dev Container Features when official Features and a small idempotent setup script suffice.
- Do not solve concurrent-clone Compose collisions caused by the fixed root Compose project name in this scope.

## Files to add or modify

| Path | Change |
| --- | --- |
| `.devcontainer/devcontainer.json` | Define the Compose-backed editor and headless contract, locked Features, non-root user, lifecycle command, service startup, mounts, and forwarded ports. |
| `.devcontainer/Dockerfile` | Build from a pinned official Ubuntu Dev Container base and install pinned uv plus stable image-level prerequisites without repository source or secrets. |
| `.devcontainer/compose.yml` | Add the `workspace` service, source bind, Compose-network database configuration, keep-alive command, and disposable cache/dependency volumes. |
| `.devcontainer/devcontainer-lock.json` | Commit the lock generated by the selected pinned `@devcontainers/cli`; do not hand-author it. |
| `.devcontainer/setup.sh` | Idempotently verify tool pins, install Pi and locked dependencies, prepare Chromium, and repair only named-volume ownership. |
| `.devcontainer/smoke-test.sh` | Exercise tool versions, non-root execution, Nx discovery, Chromium, Docker/Compose, PostgreSQL, API readiness, and web serving without a TTY. |
| `.devcontainer/README.md` | Document editor and CLI workflows, credentials, Docker authority, caches, browser scope, troubleshooting, and safe teardown. |
| `.github/workflows/devcontainer.yml`, `.github/.gitkeep` | Add pinned headless CI build/smoke coverage and remove the placeholder. |
| `.dockerignore` | Exclude `.pi/npm`, `.pi/git`, `.pi-subagents`, `.pi-tasks`, and other generated agent runtime state while retaining tracked project configuration. |
| `projects/web/Dockerfile` | Align Corepack activation with pnpm 11.15.1. |
| `.vscode/extensions.json` | Recommend the Dev Containers extension without making it a headless requirement. |
| `docs/design-docs/0001-devcontainer-workspace.md`, `docs/design-docs/README.md` | Record and index the topology, host-Docker trust boundary, alternatives, and consequences. |
| `README.md`, `CONTRIBUTING.md`, `AGENTS.md` | Add the supported human and agent entry paths, prerequisites, commands, and trust constraints while retaining host setup. |
| `docs/ARCHITECTURE.md` | Record the development workspace and its PostgreSQL connection separately from application topology. |
| `docs/coding-agent-harness/README.md`, `docs/coding-agent-harness/configuration.md` | Explain container Pi provisioning, project configuration ownership, headless use, and credential boundaries. |
| `docs/references/environment-variables.md` | Name the workspace-run API as a `DATABASE_URL` consumer and document its Compose default. |

## Steps

- [x] **1. Record the development topology and Docker trust decision.**
  - Add `docs/design-docs/0001-devcontainer-workspace.md` with context, decision, consequences, and alternatives: reuse `web`, reuse `api`, Docker-in-Docker, no Docker access, and separate human/agent definitions.
  - State that host-socket access is host-daemon authority allowed only for the explicitly trusted audience, and that less-trusted agents require a disposable VM, remote/rootless daemon, or a separate restricted environment.
  - Register the decision in `docs/design-docs/README.md`.
  - Acceptance: the record defines the workspace-to-PostgreSQL connection and security boundary without changing application connectivity.

- [x] **2. Create the pinned image and Dev Container metadata.**
  - Add a multi-architecture Ubuntu 24.04 Dev Container image definition with reviewed digest pins where practical and uv 0.11.14 from its versioned upstream image.
  - Configure exact Node/pnpm and Python Feature options, Docker-outside-of-Docker, `service: workspace`, the non-root user, UID adjustment, workspace path, forwarded ports 4200 and 8000, `runServices` for only `workspace` and `postgres`, explicit shutdown behavior, and the setup hook.
  - Generate the Feature lock with a pinned `@devcontainers/cli` and enforce frozen-lock behavior; keep optional editor customizations separate from required behavior.
  - Acceptance: `devcontainer read-configuration` resolves the expected Compose files, service, user, ports, and lifecycle hook; `devcontainer build --frozen-lockfile` succeeds with no floating `latest` inputs or credentials.

- [x] **3. Add the dedicated Compose workspace and isolated state.**
  - Build `workspace` from `.devcontainer/Dockerfile`, bind the checkout, keep the service alive, use init handling, and wait for healthy `postgres`.
  - Set the workspace's `DATABASE_URL` to the existing PostgreSQL service and set the Playwright browser path.
  - Isolate the pnpm store, uv cache, Playwright browsers, root/package `node_modules`, API `.venv`, and relevant Nx/Pi generated state with named volumes where host/container ABI or performance requires it.
  - Do not republish PostgreSQL or add application ports beyond the existing forwarding contract.
  - Acceptance: merged Compose configuration validates; `devcontainer up` starts only `workspace` and `postgres`; the non-root user can write cache volumes without creating root-owned source files.

- [x] **4. Implement non-interactive, idempotent setup.**
  - Assert the approved Node, pnpm, Python, and uv versions before dependency installation.
  - Install `@earendil-works/pi-coding-agent@0.83.0` only when the active `pi --version` differs, then run `pnpm install --frozen-lockfile`, `uv sync --project projects/api --locked`, and Chromium dependency/browser setup.
  - Keep setup safe to rerun, avoid broad ownership changes to the bind mount, and emit actionable diagnostics for missing registries, Docker, or required credentials.
  - Never start application servers, trust Pi automatically, perform interactive authentication, or download all browsers.
  - Acceptance: two consecutive setup runs succeed, all tool versions match, Chromium launches headlessly, dependency locks remain unchanged, and no secret or profile appears in tracked paths.

- [x] **5. Add a headless smoke contract.**
  - Verify non-root identity, tool pins, frozen/locked installs, Nx project discovery, Chromium launch, Docker access, merged Compose resolution, and healthy PostgreSQL.
  - Start API through Nx, wait for `/api/v1/health/ready`, then start web through Nx and request its root page. Use traps to stop every process and print useful logs on failure.
  - Check that lockfiles and tracked generated files are unchanged.
  - Acceptance: `.devcontainer/smoke-test.sh` passes through `devcontainer exec` without VS Code, a TTY, or provider credentials.

- [x] **6. Align existing tooling and protect Docker build contexts.**
  - Change the web image's pnpm activation from 11.9.0 to 11.15.1.
  - Exclude generated Pi package, Git/worktree, subagent, and task runtime state from Docker contexts; retain tracked `.pi/settings.json` and runtime-visible skills through the bind-mounted checkout.
  - Acceptance: root metadata, web image, and Dev Container agree on pnpm; existing root Compose and web image builds still validate; local Pi/session artifacts cannot enter build contexts.

- [x] **7. Add pinned CI coverage for the headless path.**
  - Add a path-filtered workflow that pins `@devcontainers/cli` and GitHub Actions, resolves configuration, builds/starts with the frozen Feature lock, runs the smoke script through `devcontainer exec`, and always collects diagnostics and tears down.
  - Set a timeout and provide no model/provider credentials; only `pi --version` is exercised.
  - Acceptance: a fresh runner detects stale Feature/dependency locks, missing Chromium, broken non-root setup, unhealthy PostgreSQL, or failed API/web startup without logging secrets.

- [x] **8. Document human and agent operation.**
  - Make `.devcontainer/README.md` the detailed guide for VS Code "Reopen in Container" and pinned CLI `up`/`exec` use.
  - Document default services, Nx serve commands, ports, Chromium scope, the explicit all-browser command, credential forwarding/injection, cache reset, and teardown that does not stop the active workspace unexpectedly.
  - Warn prominently that Docker-outside-of-Docker controls the host daemon and is not an untrusted-agent sandbox.
  - Update root onboarding, agent policy, architecture, Pi configuration/bootstrap guidance, editor recommendations, and environment-variable consumers.
  - Acceptance: a new human can start without host Node/Python, a headless agent can start without an editor/TTY, links resolve, and no documentation implies automatic trust or sandboxing.

- [x] **9. Validate from clean state and complete independent review.**
  - Run the Dev Container build and smoke path from clean disposable volumes, the existing web image build, root/merged Compose checks, focused Nx checks, and the required affected checks inside the container.
  - Validate on Docker Desktop and native Linux, and on amd64/arm64, only where support is claimed; document any narrower verified matrix.
  - Run independent security, reproducibility, and documentation reviews, apply accepted in-scope findings serially, and inspect the final diff for secrets, generated runtime state, and unintended lock changes.
  - Acceptance: required checks pass, reviewers report no blockers, and only intended source/configuration/documentation files are present.

## Verification

Run from the repository root unless noted:

```bash
docker compose config --quiet
docker compose -f compose.yml -f .devcontainer/compose.yml config --quiet

pnpm dlx @devcontainers/cli@<approved-version> read-configuration --workspace-folder .
pnpm dlx @devcontainers/cli@<approved-version> build --workspace-folder . --frozen-lockfile
pnpm dlx @devcontainers/cli@<approved-version> up --workspace-folder .
pnpm dlx @devcontainers/cli@<approved-version> exec --workspace-folder . bash -lc '.devcontainer/setup.sh'
pnpm dlx @devcontainers/cli@<approved-version> exec --workspace-folder . bash -lc '.devcontainer/setup.sh'
pnpm dlx @devcontainers/cli@<approved-version> exec --workspace-folder . bash -lc '.devcontainer/smoke-test.sh'

docker build -f projects/web/Dockerfile --target dev -t workspace-web-dev .
pnpm dlx @devcontainers/cli@<approved-version> exec --workspace-folder . bash -lc 'pnpm exec nx affected -t lint test --base=origin/main --parallel=3'

git diff --check
git diff --exit-code -- pnpm-lock.yaml projects/api/uv.lock
git status --short
```

The implementation selects and records the exact Dev Container CLI version before replacing `<approved-version>`. CI repeats the headless build, smoke, diagnostics, and teardown path. Any claimed platform/architecture support requires direct or CI evidence.

## Documentation impact

This changes developer setup, agent execution, tool provisioning, Compose topology, configuration ownership, and security assumptions. Update the living documentation in the file map above. `docs/ARCHITECTURE.md` records the workspace-to-PostgreSQL connection, and the design record preserves the rationale and host-Docker trust boundary.

## Risks and recovery

- **Host Docker authority:** a process with socket access can control the host daemon. Close the environment, revoke exposed credentials, inspect affected containers/volumes, and move less-trusted work to a disposable or remote daemon.
- **Host/container dependency contamination:** incomplete volume coverage can mix macOS/Windows and Linux artifacts. Remove generated host directories, recreate the named volumes, and rerun locked setup.
- **Supply-chain drift:** images, Features, CLI packages, Actions, and registries are new inputs. Pin reviewed versions/digests, commit the generated Feature lock, and enforce frozen behavior in CI.
- **Credential persistence:** interactive login in persistent home/cache storage can outlive the session. Do not persist auth directories by default; use ephemeral injection and least-privilege credentials.
- **Lifecycle disruption:** broad `docker compose down` can stop the active workspace. Document service-specific commands and perform full teardown from the host or Dev Container CLI.
- **Cache staleness and setup cost:** persistent caches speed first use but can become incompatible after tool changes. Provide a single documented cache-reset procedure and prove clean restoration.
- **Compose collisions:** the root fixed project name can collide across concurrent clones/worktrees. Keep this unsupported in this scope and state it clearly.

## Assumptions requiring approval

- Only trusted humans and trusted coding agents use this definition, and granting them host Docker daemon authority is acceptable.
- One shared full-capability definition is preferred over separate privileged-human and restricted-agent definitions.
- Host development remains supported.
- PostgreSQL starts by default; web and API normally run through Nx in the workspace.
- Chromium-only default provisioning is acceptable; Firefox and WebKit remain explicit.
- `@earendil-works/pi-coding-agent@0.83.0` is the intended Dev Container Pi distribution and pin.
- Adding a pinned Dev Container CI workflow and its external build inputs is acceptable.
- Support is claimed only for the platform/architecture matrix verified during implementation.
- Concurrent Compose clones/worktrees remain out of scope.

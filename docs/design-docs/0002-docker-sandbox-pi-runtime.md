# 0002: Optional Docker Sandbox Pi runtime

## Context

Host development and the Compose-backed [Dev Container workspace](0001-devcontainer-workspace.md) remain supported. The Dev Container gives trusted workspace processes host-Docker authority and is not an isolation boundary.

Docker Sandboxes provides a separate, manual Pi runtime. The repository controls the Pi package through `PI_PACKAGE` in [`tools/toolchain.env`](../../tools/toolchain.env), the single authority for every pinned toolchain version. The Dev Container setup/smoke scripts and Sandbox bootstrap derive their assertions from it through [`tools/lib/shell.sh`](../../tools/lib/shell.sh).

## Decision

The repository provides `.sandbox/launch-pi.sh` for a Sandbox `shell` agent. It accepts only `sbx` 0.38.0 and selects `docker.io/docker/sandbox-templates:shell` by default. `--docker` selects `docker.io/docker/sandbox-templates:shell-docker`. Template save/load and custom templates are not part of this runtime.

Clone mode is the default. The launcher creates an invocation-owned standalone clone of repository `HEAD` with `git clone --no-local --no-hardlinks`, then validates the clone before passing it to `sbx --clone`. It rejects ignored or untracked content, symlinks, submodules, path escapes, and prohibited tracked paths. Direct mode omits `--clone` and is an explicit trusted full-checkout read/write mode.

The optional user Pi input mounts a mode-0700 invocation-owned directory containing a byte-for-byte `settings.json` snapshot read-only, and mounts the validated extensions directory separately read-only. The snapshot exists because `sbx` 0.38.0 accepts directory workspaces rather than a settings file workspace. The Sandbox bootstraps symlinks from those inputs into its local Pi agent paths.

See the [Docker Sandbox Pi reference](../references/docker-sandbox-pi.md) for operation, validation boundaries, recovery, and teardown.

## Consequences

- The Sandbox is opt-in and does not change host development, root Compose, or the trusted Dev Container path.
- The launcher does not mount host Pi authentication, sessions, trust, models, prompts, skills, themes, npm/Git state, caches, SSH state, general home, or the host Docker socket.
- Settings/extensions opt-in is trusted input. It does not sanitize settings, project them to packages, or copy extensions individually. It rejects only a top-level legacy `apiKeys` field without reporting values.
- The settings snapshot is removed with invocation-owned state during teardown. Concurrent host rewrites are unsupported because the Sandbox reads a launch-time snapshot.
- Pi package and Git state are writable inside the Sandbox. Global package declarations install Linux-native copies there rather than reusing host artifacts.
- Sandbox-scoped proxy credentials remain outside the VM. Pi OAuth state is sandbox-local and can persist while the VM exists; deleting local state does not revoke an upstream credential or grant.
- The recorded `sbx` 0.38.0 evidence covers the named templates, clone lifecycle, `sbx cp`, policy interfaces, a loopback port mapping, nested Docker isolation, and Pi installation/version startup. It does not establish provider, enterprise OAuth, llama.cpp, full nested Compose, real user Pi inputs, or requested API/web publication support.

## Alternatives considered

- **Use the ordinary checkout by default:** it can contain ignored, untracked, cached, credential, and package state.
- **Use a Git worktree as the clone source:** `sbx` 0.38.0 rejects Git worktrees.
- **Mount `settings.json` directly:** `sbx` 0.38.0 rejects file workspaces.
- **Use the Dev Container as a Sandbox:** its Docker-outside-of-Docker access intentionally exposes host-daemon authority to trusted users.

See [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) for the current runtime topology.

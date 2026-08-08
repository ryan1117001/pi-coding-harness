# Exact Docker Sandboxes 0.38.0 evidence

Result: `LIVE-EVIDENCE-PASS`.

> Sections 1-9 below are the original **pre-implementation** pass: they exercise
> `sbx` primitives directly, not `.sandbox/launch-pi.sh`. The
> [implementation evidence](#implementation-evidence-2026-08-08) at the end
> records the first end-to-end runs of the launcher itself and corrects three
> claims that pre-implementation testing could not reach.

The user explicitly authorized this plan-bounded disposable smoke. All created names used the `pi-sbx-live-*`, `pi-sbx-evidence-*`, or `pi-sbx-nested*` prefixes. No pre-existing sandbox, secret, listener, policy, worktree, remote, or template was removed or altered. The pre-existing global `openai` OAuth entry was listed by name/scope only and was not inspected, used, changed, or removed; provider smoke was not run.

## Version and host readiness

- `sbx version` returned `sbx version: v0.38.0 c022b14634c4bea846ca12870d1d5e97d5868b54`.
- `sbx diagnose -o json` reported all nine checks passing: CLI, binary/daemon version, healthy daemon, storage, permissions, socket, and authentication.
- Initial sandbox inventory was empty. Initial network policy was default deny with no broad active allow. `sbx template ls --json` initially had no images; the exact built-in templates used by the smoke are now cached and listed as `docker.io/docker/sandbox-templates:shell` and `docker.io/docker/sandbox-templates:shell-docker`. No custom tag, save, load, or export was created.

## Exact template syntax

Exact 0.38.0 live behavior plus Docker's official template documentation established that `--template shell` is not a valid Docker Hub shorthand: it attempted to pull image `shell` and failed 403. Docker's official documented rule says `sbx` does not infer `docker.io`, and built-in variants are published as `docker/sandbox-templates:<variant>`. The live-proven exact selections are therefore:

- normal shell: `--template docker.io/docker/sandbox-templates:shell`
- nested Docker shell: `--template docker.io/docker/sandbox-templates:shell-docker`

The shell agent without an explicit template defaults to the `shell-docker` variant in 0.38.0; the implementation must select the non-Docker reference explicitly for normal mode.

## Read-only settings/extensions workspace constraint

Exact 0.38.0 live behavior rejects a regular file as an extra workspace with `workspace path exists but is not a directory`. Therefore the validated `settings.json` cannot itself be passed as a workspace path. A live-proven representation that preserves the approved boundary is an invocation-owned mode-0700 staging directory containing only a byte-for-byte full `settings.json`, mounted `:ro`, plus the validated extensions root mounted separately `:ro`. A disposable test proved both directories appeared at their host absolute paths as read-only `virtiofs` mounts, the full settings file and extension fixture were readable, and appending to settings failed. No packages-only projection, sanitization, whole-agent mount, or individual extension copy is required. Concurrent host rewrites remain unsupported because the staged settings input is an invocation snapshot; teardown must delete the invocation-owned staging directory. The implementation should validate the original file immediately before copying and reject symlinks/path replacement/legacy top-level `apiKeys` without printing values.

## Clone, lifecycle, attach, copy, and recovery

A unique tracked-only clean local clone of repository `HEAD` was selected. Exact successful creation form:

`sbx create shell <clean-source> --clone --name <unique-name> --template docker.io/docker/sandbox-templates:shell --quiet`

Observed:

- `sbx ls --json` reported the exact selected source path and `agent: shell`.
- The private writable clone started at the selected source HEAD.
- `/run/sandbox/source` resolved to the selected host source and was a read-only `virtiofs` mount (`ro,nosuid,nodev`).
- A duplicate create with the same name failed with exit 1 and advised attaching rather than silently reusing it.
- Noninteractive attach with `sbx run shell --name <name> -- -lc ...` returned successfully; creation-only options were not supplied.
- `sbx cp` succeeded host-to-sandbox and sandbox-to-host.
- Clone creation added only the generated `sandbox-<name>` remote in the selected disposable clone. A sandbox commit was visible through `git ls-remote`, fetched into `refs/sandboxes/<name>/main`, and the recovered file matched. No upstream sandbox credential was configured.
- `sbx rm <name> --force` removed each invocation-owned sandbox. No `--all`, reset, or pre-existing name was used.

## Policy evidence

Exact 0.38.0 help and live behavior proved:

- `sbx policy ls <name> --include-inactive --wide|--json`
- `sbx policy check network --sandbox <name> <host:port> --json`
- `sbx policy allow network --sandbox <name> <comma-separated exact resources>`
- `sbx policy rm network --sandbox <name> --id <RULE_ID>`

A scoped `example.com:443` rule made only that host/port positive; `example.com:444` and `127.0.0.1:443` stayed denied. The editable local rule ID was recorded, removed by ID, and absent afterward.

For a nested image pull, only exact scoped registry endpoints were temporarily allowed: `registry-1.docker.io:443`, `auth.docker.io:443`, `production.cloudflare.docker.com:443`, and the live-discovered `production.cloudfront.docker.com:443`. The first three were intentionally insufficient and failed closed. Adding the fourth exact endpoint allowed `alpine:3.22` to pull. `example.com:443` remained denied. All four invocation-owned rule IDs were removed by ID before sandbox removal, and the final policy inventory returned to the default-deny baseline.

## Ports

Inside the explicit non-Docker shell template, an invocation-owned HTTP server listened on sandbox port 18080. `sbx ports <name> --publish 18080/tcp4` allocated `127.0.0.1:49154`; host loopback received HTTP 200. The mapping was listed by `sbx ports <name> --json`, unpublished with `sbx ports <name> --unpublish 127.0.0.1:49154:18080/tcp4`, and absent afterward. No VM or host port 5432 was published. Clone mode separately used an automatically managed loopback 9418 Git-daemon mapping.

## Nested Docker isolation

The explicit `docker.io/docker/sandbox-templates:shell-docker` template resolved and ran. Evidence:

- `/var/run/docker.sock` was a socket inside sandbox `/run` tmpfs, not a host mount.
- Docker context was `default`, client/server were Linux arm64 Docker Engine 29.7.1, and the initial inner container and image inventories were empty.
- This differed from and did not expose host daemon state.
- After exact scoped registry policy, `docker run --rm --pull=never alpine:3.22 ...` printed `nested-container-ok`.
- The nested container had no Docker socket and its request to `https://example.com` was blocked while exact registry destinations remained permitted.
- No outer ports were published by the `shell-docker` sandbox.

## Pi startup

In an explicit non-Docker shell sandbox, a single sandbox-scoped `registry.npmjs.org:443` rule was sufficient for a normal-user `npm install -g @earendil-works/pi-coding-agent@0.84.1`. `command -v pi` resolved `/usr/local/share/npm-global/bin/pi`, and `pi --version` printed `0.84.1`. The process ran as uid/gid `agent`; no host Pi state or credentials were mounted. The invocation-owned registry rule was removed by recorded ID and the sandbox was removed. A later `pi --help` check returned nonzero in the noninteractive shell, so only version/startup—not interactive provider operation—is claimed.

## Cleanup and residual bounds

- A first delegated evidence attempt timed out after gathering clone/copy/recovery/policy evidence and left one invocation-owned sandbox and one editable local rule. The parent identified the exact name/ID, removed only that rule, unpublished its invocation-owned mapping, removed only that sandbox, preserved the value-free log, and deleted its matching temporary directory.
- Every continuation script used bounded subprocess timeouts and `finally` cleanup. Final `sbx ls --json` was empty; no invocation-owned editable policy remained; all matching temporary paths were removed; repository remotes remained `origin`; the pre-existing `/private/tmp/pi-harness-verify` worktree remained untouched.
- Built-in `shell` and `shell-docker` template images remain in the Sandbox runtime cache by documented 0.38.0 behavior. They are official built-in variants, not custom tags or exports.
- Provider/API-key/OAuth, enterprise authentication, real host Pi settings/extensions, llama.cpp, and root Compose were not exercised in this pre-implementation evidence pass. The global OpenAI entry requires affected provider smoke to refuse. Those cases remain bounded to later implementation smoke or documented unsupported status.

Raw value-free logs:

- `.pi-subagents/artifacts/outputs/2026_08_07-docker-sandbox-live-evidence-partial.log`
- `.pi-subagents/artifacts/outputs/2026_08_08-docker-sandbox-live-evidence-continuation.log`

## Implementation evidence (2026-08-08)

First end-to-end runs of `.sandbox/launch-pi.sh` itself, on `sbx version: v0.38.0
c022b14634c4bea846ca12870d1d5e97d5868b54`. Disposable sandboxes only, each removed;
`sbx ls`, `sbx policy ls --include-inactive` and `sbx template ls` returned to their
pre-run baselines after every run.

### Corrections to the pre-implementation pass

1. **`sbx ls --json` retains the `:ro` suffix on extra workspaces.** A sandbox created
   with `sbx create shell SRC --clone EXTRA:ro` reports
   `["…/SRC", "…/EXTRA:ro"]`. The primary workspace has no suffix. Paths are echoed
   exactly as passed — `sbx` does not canonicalize them — so the launcher canonicalizes
   its own state root to keep one spelling.

2. **The in-sandbox clone is mounted at the same absolute path as the host source.**
   For a clone-mode sandbox, `sbx exec` starts in the private writable clone at that
   path, at the selected `HEAD`; `/run/sandbox/source` is a separate read-only
   `virtiofs` mount of the original. The recorded staging path is therefore also a
   valid `-w` target.

3. **Both built-in templates ship an uneditable scoped network rule.** Creation attaches
   `{"name":"kit:<sandbox>","scope":"sandbox:<sandbox>","resource_type":"network",
   "decision":"allow","resources":["openrouter.ai"],"origin":"scoped","editable":false}`.
   It is removed automatically with the sandbox and cannot be removed by ID, so the
   launcher acknowledges it rather than owning it.

### Policy rule scoping

Measured on a live sandbox:

| Probe | Rule `openrouter.ai` (template, host-only) | Rule `registry.npmjs.org:443` (launcher, exact) |
| --- | --- | --- |
| exact `host:443` | allow | allow |
| alternate `host:444` | **allow** | deny |
| `host:80` | **allow** | not probed |
| `unexpected-subdomain.host:443` | deny | deny |
| `host.evil.example:443` | deny | not probed |
| unrelated `example.invalid:443` | deny | deny |

A host-only rule covers every port on that host; an exact `host:port` rule does not.
Both deny subdomains. `sbx policy rm network --sandbox N --id ID` removed the launcher's
rule and `sbx policy ls N --include-inactive --json` proved its absence.

### Template image contents

`docker.io/docker/sandbox-templates:shell` is Ubuntu 26.04 running as uid/gid 1000
`agent`, in groups `sudo` and `docker`, with passwordless sudo. It ships Python 3.14.4,
pip 25.1.1, uv 0.9.26, node v22.22.1, npm 9.2.0, git 2.53.0, and no pnpm. The pinned
Python matches the workspace pin, so the bootstrap asserts rather than provisions it;
node, uv and pnpm are installed to per-user prefixes that precede `/usr/local` on `PATH`.

### Lifecycle

`.sandbox/smoke-test.sh` under `SANDBOX_LIVE_SMOKE=1` created a `--docker --with-user-pi`
clone-mode sandbox, ran both bootstrap phases, asserted the full pinned toolchain and the
read-only settings/extensions links inside the VM, proved a repeated bootstrap left the
clone clean, copied files both directions, confirmed no application or database port was
published, validated root Compose inside the VM, then removed every invocation-owned
resource. Clone mode requires the launcher's own scripts to be committed, since `--clone`
sends repository `HEAD`.

### Still not established

Provider/API-key/OAuth flows, Codex/Copilot/Anthropic Enterprise, Cursor credentials and
extensions, llama.cpp host access, and application port publication remain unverified and
unsupported. `--secret-service`, `--publish-api` and `--publish-web` are rejected by the
launcher.

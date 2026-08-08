# Docker Sandbox Pi runtime

The Docker Sandbox runtime is an optional manual path. It does not replace [host development](../../CONTRIBUTING.md) or the trusted [Dev Container](../../.devcontainer/README.md). The Dev Container has host-Docker authority and is not a Sandbox.

## Evidence boundary

The launcher requires `sbx` 0.38.0 or newer and warns when it runs above the verified 0.38.0. Both bounds live in [`tools/toolchain.env`](../../tools/toolchain.env) as `SBX_MINIMUM` and `SBX_VERIFIED`. The committed lifecycle forms are bounded by the recorded [0.38.0 live evidence](evidence/2026-08-08-docker-sandbox-sbx-0.38.0.md): the `shell` agent; `docker.io/docker/sandbox-templates:shell`; `docker.io/docker/sandbox-templates:shell-docker`; clone lifecycle and attach; policy interfaces; `sbx cp`; loopback port publication; nested Docker isolation; and full launcher bootstrap through Pi startup.

The evidence does not establish provider/API-key/OAuth flows, Codex Enterprise, GitHub Copilot Enterprise, Anthropic Enterprise, Cursor credentials/extensions, llama.cpp host access, real user Pi inputs, full nested Compose startup, or API/web port publication. Codex Enterprise, GitHub Copilot Enterprise, and Anthropic Enterprise remain unsupported/unverified until the approved matrix is recorded. Cursor remains optional and requires separate extension and credential evidence despite the Pi pin.

## Prerequisites and routine checks

Run commands from the repository root. The launcher requires Git, Python 3, and `sbx`. It installs the repository-controlled Pi package named by `PI_PACKAGE` in [`tools/toolchain.env`](../../tools/toolchain.env), which is the single authority for every pinned version; the Dev Container setup and smoke scripts derive their assertions from the same file.

Clone mode sends repository `HEAD` to the Sandbox, so the launcher's own scripts must be committed before a clone-mode launch can bootstrap.

```bash
pnpm sandbox:test
```

`sandbox:test` runs only the fake-`sbx` contract suite. It does not launch a Sandbox and is the only Sandbox check suitable for generic CI.

Run the live smoke only on an eligible, logged-in host that is explicitly authorized for the disposable work:

```bash
SANDBOX_LIVE_SMOKE=1 .sandbox/smoke-test.sh
```

The smoke generates its own name and temporary inputs. It records inventories, uses `EXIT`, `INT`, and `TERM` cleanup, and removes only invocation-owned resources.

## Create, attach, and remove

Create a detached normal Sandbox:

```bash
.sandbox/launch-pi.sh --name NAME --detached
```

By default, the launcher creates a unique standalone clone of repository `HEAD` with `git clone --no-local --no-hardlinks`, checks it out detached, validates it, and sends that source to `sbx create shell <source> --clone`. The read-only `/run/sandbox/source` mount refers to that selected source. The private Sandbox clone starts at the selected `HEAD`.

The clone preflight rejects ignored or untracked state, symlinks, submodules, canonical path escapes, `.env*` except `.env.example`, `.npmrc`, `.pi/npm`, `.pi/git`, `auth.json`, `node_modules`, `.venv`, private-key paths, and tracked `.pem` or `.key` files. It does not use the ordinary checkout's ignored or untracked state.

Use nested Docker only when requested:

```bash
.sandbox/launch-pi.sh --name NAME --docker --detached
```

`--docker` selects the recorded `shell-docker` template. The evidence establishes a VM-local Docker socket/daemon with no initial host container or image visibility, and a blocked nested-container request to an unapproved destination. It does not establish other Docker or network behavior.

Direct mode exposes the selected checkout read/write, including `.git`, ignored files, caches, hooks, package trees, and local credentials. It omits clone mode and requires both flags:

```bash
.sandbox/launch-pi.sh --name NAME --direct --trust-direct --detached
```

Attach accepts no creation-only template, workspace, secret, user-input, publication, or bootstrap options:

```bash
.sandbox/launch-pi.sh --attach NAME
```

Remove only a Sandbox created by this launcher:

```bash
.sandbox/launch-pi.sh --remove NAME
```

Removal deletes recorded policy rules and scoped secrets, removes the named Sandbox, deletes the invocation-owned clone and settings snapshot, then deletes its owned state directory. It does not remove an unowned Sandbox. Preserve work before removal with the generated `sandbox-NAME` remote or the recorded `sbx cp` interface; review and push upstream from the host. The launcher does not configure upstream Git credentials.

## Trusted user Pi input

`--with-user-pi` is disabled by default. It reads `PI_USER_SETTINGS` and `PI_USER_EXTENSIONS`; their defaults are `~/.pi/agent/settings.json` and `~/.pi/agent/extensions`. The launcher accepts only a regular non-symlink settings file and an extensions directory whose root is not a symlink.

Because `sbx` accepts only directory workspaces, the launcher copies the full settings file byte-for-byte into an invocation-owned mode-0700 `settings-input` directory, mounts that directory read-only, and mounts the extensions directory separately read-only. It links the mounted settings snapshot and extensions directory into sandbox-local `~/.pi/agent/` paths. It does not mount the whole host agent directory or host `auth.json`, sessions, trust, models, prompts, skills, themes, npm/Git state, caches, SSH state, or general home.

The launcher structurally rejects a top-level legacy `apiKeys` field without printing values. All other settings and extension content remains user-inspected trusted readable/executable input; it can contain commands, secrets, and host-only paths. The launcher does not sanitize settings, project them to packages, or copy extensions file by file. Sandbox settings writes fail through the read-only input; relaunch without the opt-in to change Sandbox settings. Concurrent host rewrites are unsupported because the input is a launch-time snapshot. Teardown deletes the snapshot.

Global package declarations install Linux-native copies in Sandbox-local writable Pi package and Git state. Do not reuse host package artifacts.

| Variable | Consumer | Default or effect |
| --- | --- | --- |
| `PI_USER_SETTINGS` | `.sandbox/launch-pi.sh` | Host settings source; defaults to `~/.pi/agent/settings.json` for `--with-user-pi`. |
| `PI_USER_EXTENSIONS` | `.sandbox/launch-pi.sh` | Host extensions source; defaults to `~/.pi/agent/extensions` for `--with-user-pi`. |
| `SANDBOX_STATE_ROOT` | `.sandbox/launch-pi.sh` | Absolute, owned, non-symlink state root; defaults to `~/.local/state/pi-coding-harness/sandboxes`. |
| `SANDBOX_BOOTSTRAP_NETWORK` | `.sandbox/launch-pi.sh` | Comma-separated exact bootstrap destinations; replaces the launcher's default list. Wildcards are rejected. |
| `SANDBOX_EXPECTED_TEMPLATE_NETWORK` | `.sandbox/launch-pi.sh` | Comma-separated exact `host:port` rules the template is allowed to ship; replaces the default `openrouter.ai:443`. Acknowledged rules are permitted, not required. Set this when using a template whose built-in policy differs. |
| `SANDBOX_SKIP_BROWSER` | launcher and bootstrap | `1` skips Chromium installation and launch checks. |
| `SANDBOX_LIVE_SMOKE` | `.sandbox/smoke-test.sh` | Must equal `1` to authorize its live smoke. |
| `SANDBOX_SMOKE_COMPOSE` | `.sandbox/smoke-test.sh` | `1` enables its nested PostgreSQL Compose smoke. |

`SANDBOX_PI_SETTINGS_SOURCE` and `SANDBOX_PI_EXTENSIONS_SOURCE` are launcher-to-Sandbox bootstrap inputs, not host configuration.

## Credentials, egress, and ports

The launcher rejects `--secret-service`, `--publish-api`, and `--publish-web`. They are parsed only so the failure names them; no credential or port-publication path is implemented. Manage those directly with `sbx secret` and `sbx ports` against a named Sandbox, and remember that deleting a scoped proxy entry or the Sandbox itself does not revoke an upstream API key or OAuth grant.

The launcher inventories global secret names and scopes without reading values, and refuses to start when a global registry credential could contaminate the Sandbox. Pi-managed OAuth uses sandbox-local `auth.json`; it is not copied from the host and can persist until Sandbox removal. Provider smoke is not supported by the recorded evidence; the smoke refuses the observed global OpenAI credential path rather than using it.

Before bootstrap, the launcher inspects the named Sandbox policy including inactive rules, rejects broad active network allows, and checks denied destinations. Bootstrap permits exact destinations only, records every added rule ID, performs a positive check after each addition, and removes the recorded IDs. All policy inspection is Sandbox-scoped: `sbx policy ls` without a Sandbox name returns one overview row per policy and cannot prove a scoped rule absent.

Rule scoping is not uniform, and the launcher's negative probes follow the measured behavior:

| Rule form | Added by | Covers |
| --- | --- | --- |
| `host:port` | the launcher, for every bootstrap destination | that port only; other ports and subdomains stay denied |
| `host` | the built-in templates, as an uneditable `kit:<sandbox>` rule | every port on that exact host; subdomains stay denied |

Because a template rule is host-scoped, the launcher probes an alternate port as denied only for the exact rules it added itself. It probes subdomain denial for both forms, and always probes unrelated destinations.

No outer application or database port is published by default, and port 5432 is never requested. Clone mode manages one loopback Git-daemon mapping automatically. The llama.cpp `host.docker.internal` and named-Sandbox `localhost:<PORT>` pairing is unsupported until exact positive and negative evidence exists.

## Teardown and non-goals

The launcher and smoke use owned-resource cleanup only. Do not use `sbx reset`, bulk removal, global secrets, global/wildcard policy, template save/load, custom template tags, or template exports. Sandbox VMs and Pi state can persist until removal; inspect resources before reusing a name.

For the complete architecture boundary, see [0002: Optional Docker Sandbox Pi runtime](../design-docs/0002-docker-sandbox-pi-runtime.md).

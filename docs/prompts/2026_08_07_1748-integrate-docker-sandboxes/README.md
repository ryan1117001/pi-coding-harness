---
status: approved
---

# Integrate Docker Sandboxes as an optional Pi runtime

## Goal

Add a documented, reproducible, and optional Docker Sandboxes runtime for Pi without replacing host development or the trusted Docker-outside-of-Docker Dev Container. Start the repository-pinned `@earendil-works/pi-coding-agent@0.84.1` through the supported `shell` agent on an exactly selected built-in `shell` or `shell-docker` template, default to cloning a dedicated clean staging worktree, support an explicit trusted read-only user Pi settings/extensions opt-in, and bound every platform, provider, network, and isolation claim to recorded evidence. Distinguish host-stored proxy credentials, whose values do not enter the VM, from Pi-managed OAuth tokens persisted in sandbox-local `auth.json`.

## Context

- The repository currently supports host development and an optional trusted Dev Container. The Dev Container controls the host Docker daemon and is not an isolation boundary for untrusted agents; Docker Sandboxes is a separate optional route.
- The target CLI for this plan is exactly `sbx` 0.38.0. Help and disposable live evidence from exactly 0.38.0 must prove the built-in `shell` and `shell-docker` selections, Pi startup, lifecycle syntax, and nested Docker isolation before implementation commits commands. Any other version or behavioral mismatch fails closed.
- Clone mode mounts the selected Git repository read-only at `/run/sandbox/source`. Selecting the ordinary checkout would expose ignored `.pi/npm`, `.pi/git`, `node_modules`, `.venv`, environment files, and other local state. The default must therefore select a newly created, dedicated clean Git worktree containing tracked files only and must live-prove that `sbx --clone` uses that selected source. If it cannot, implementation stops for a decision.
- Direct mode omits clone mode and exposes the entire selected checkout for reads and writes, including `.git`, tracked and ignored files, caches, hooks, package trees, and workspace-local credentials. There is no invented `--direct` flag.
- Sandbox VMs persist until removal. Interactive OAuth tokens, shell history, installed packages, writable Pi state, and clone-only work can survive stop/restart.
- Docker's proxy store persists sandbox-scoped service secrets outside the VM, while global service or registry credentials may be injected into multiple sandboxes. Removing a VM or proxy entry does not revoke an upstream API key or OAuth grant.
- The repository-managed Pi authority is `@earendil-works/pi-coding-agent@0.84.1`. Dev Container setup/smoke and Sandbox bootstrap consume or assert this exact pin. Cursor remains optional third-party functionality and requires separate extension and credential evidence.
- The existing trusted Dev Container pattern permits a deliberate full read-only user Pi opt-in. The Sandbox analogue exposes only validated `~/.pi/agent/settings.json` and `~/.pi/agent/extensions` as separate read-only workspaces and wires them into sandbox-local Pi paths; it never mounts the whole host agent directory.
- A sandbox does not inherit Dev Container forwarding, Compose DNS, host Pi state, or host Docker authority. Ports, host-service access, egress, and additional inputs require explicit configuration and verification.

## Workflow and approval gates

The matching plan-specific [saved chain](../../../.pi/chains/saved-plans/2026_08_07_1748-integrate-docker-sandboxes.chain.json) uses a read-only readiness check, one serial implementation writer, serial living-documentation work, parallel read-only reviews, one serial fix pass, and final validation. It cannot run until all of these gates are met:

1. The user explicitly approves this canonical plan and it is registered in the plan index.
2. The host is authorized for any destructive live smoke, and the readiness report begins with `READY`. A `BLOCKED`, incomplete, or unresolved report makes every downstream writer a no-op.
3. Disposable live work fails closed unless installed help and live evidence are exactly `sbx` 0.38.0 and observed syntax/behavior matches the recorded contract. Revalidation of another version requires approval.

This is primarily configuration, infrastructure, and documentation work, so the repository TDD exception applies. Implementation still begins with failing fake-`sbx` command/configuration contracts. Live smoke is never an ordinary CI, install, prepare, postinstall, serve, or default-development action.

## Decisions and non-goals

### Decisions

- Preserve host development and the existing Dev Container as first-class paths. Docker Sandboxes remains opt-in.
- Use the `shell` agent. Select the built-in `shell` template for normal Pi work and `shell-docker` only for requested Docker/Compose work. Prohibit `sbx template save/load` and custom template tags or exports in this phase.
- Default to a unique dedicated clean Git worktree created from tracked repository state. Before `sbx`, reject `.env*`, `.npmrc`, `.pi/npm`, `.pi/git`, `auth.json`, `node_modules`, `.venv`, credential/private-key files, unexpected ignored or untracked entries, symlinks, and canonical path escapes under the selected source. Disposable sentinel fixtures must prove refusal or absence from `/run/sandbox/source`.
- Permit direct mode only through an explicit trusted opt-in after displaying its full checkout read/write boundary. Never silently reuse a sandbox whose agent, template, workspace mode, or source contract cannot be verified.
- Define a separate attach path. Attachment supplies no creation-only clone, template, workspace, or creation-publication options; publication changes use only the installed CLI's verified existing-sandbox interface.
- Recover clone work to the host through the generated `sandbox-<name>` remote or the installed and live-proven `sbx cp` interface. Perform any upstream push later from the host; do not configure upstream Git credentials in the sandbox.
- Add one `tools/pi-version.txt` repository-managed Pi authority containing `@earendil-works/pi-coding-agent@0.84.1`. Dev Container setup/smoke assertions, Sandbox bootstrap, synthetic contracts, and version documentation consume or assert it. This does not claim control of arbitrary host installations.
- Keep writable Pi home, browser, package, cache, Git, and session state in the VM. Do not mount the host Docker socket, whole host Pi directory, `auth.json`, sessions, trust, models, prompts, skills, themes, npm, Git state, caches, SSH, or general home.
- Support an explicit trusted full read-only user Pi settings/extensions opt-in analogous to the Dev Container pattern. Validate that `~/.pi/agent/settings.json` is a regular non-symlink file and `~/.pi/agent/extensions` is a directory that is itself not a symlink; expose them as separate extra read-only Sandbox workspaces, then wire them into sandbox-local Pi settings and extension paths without mounting the whole agent directory. Do not sanitize or project only a `packages` array, and do not individually copy selected extensions.
- Reject a top-level legacy `apiKeys` field structurally without printing keys or values. Otherwise treat opted-in settings and extension content as trusted readable/executable input that may contain commands, secrets, and host-only paths; require the user to inspect it before opting in. Global package declarations install Linux-native copies into sandbox-local writable package and Git state. Sandbox settings writes/configuration changes must fail while the read-only opt-in is enabled or require relaunch with it disabled; concurrent host rewrites are unsupported.
- Inventory secret names before smoke with exact 0.38.0 value-free forms proven from installed help and live evidence. Refuse provider smoke when a pre-existing global service secret or globally injected registry credential could satisfy the request. Never inspect, log, or compare values.
- Accept a test API key only through interactive input or stdin from an approved secret manager. Prohibit `--token`, command literals, `set -x`, environment dumps, and `sbx secret import`. Create only intended sandbox-scoped names, prove the name-only inventory, run the verified scoped equivalent of `sbx secret rm NAME SERVICE -f` before VM removal, and prove name-only absence. Never delete or alter pre-existing global credentials.
- Permit Pi-managed interactive OAuth only as an explicit in-VM action with persistent-token warnings. Codex Enterprise, GitHub Copilot Enterprise, and Anthropic Enterprise are all unsupported/unverified until an approved test records Pi version, provider, account type, organization policy, template, token location, refresh, logout, and upstream revocation. Only that tested matrix may become verified.
- Treat Cursor as optional third-party functionality, not a Docker or core Pi capability. The Pi pin satisfies its minimum Pi version, but support still requires separate extension and credential evidence.
- Establish effective egress, not merely local rule intent. Record baseline and effective policy with `sbx policy ls NAME --include-inactive --wide` or its verified JSON form; fail or mark isolation unsupported when an unapproved broad active global/profile/kit/organization rule applies. Use the installed CLI's verified `sbx policy check network` forms for positive checks of every approved host/port and negative checks of unapproved hosts, alternate ports, localhost ranges, and wildcard behavior.
- Record every added local policy rule ID, use no global or wildcard rule, and remove only those IDs with the verified `sbx policy rm network --sandbox NAME --id ...` form during teardown. Prove no invocation-owned rule remains. Policy logs supplement but do not replace effective-policy and negative authorization checks.
- For `shell-docker`, verify the daemon/socket is sandbox-local: no host socket mount, no inherited host Docker context, and no visibility of host daemon containers/images. Probe blocked network destinations from both the outer shell and a nested disposable container.
- Root Compose publishes 5432 into the VM, but the outer Sandbox publication layer publishes no port by default and never publishes VM port 5432 by default. Optional 4200/8000 publication uses collision-safe ephemeral host ports, discovered through the installed CLI's JSON port inventory and verified loopback-only.
- Pair in-sandbox host service address `host.docker.internal:<PORT>` with only the exact named-sandbox `localhost:<PORT>` policy destination after live verification. Do not infer support from syntax alone.

### Non-goals

- Do not replace, wrap, or weaken host or Dev Container development.
- Do not reuse `.devcontainer/setup.sh` inside a Sandbox; its environment and privilege assumptions differ.
- Do not change application source, browser-to-API behavior, root Compose definitions, Nx project configuration, or project `.pi/settings.json` merely to add this runtime.
- Do not imply clone mode hides the selected source or direct mode isolates it.
- Do not add `sbx` as a workspace dependency, invent unsupported CLI syntax, use experimental kits/custom-secret substitution, or save/load templates.
- Do not automate interactive OAuth or claim enterprise/provider/platform/template compatibility without the required live matrix.
- Do not run live Sandbox smoke in generic CI or from default package lifecycle/development commands.
- Do not mount the whole host Pi agent directory, copy selected extensions one by one, reduce settings to a packages-only projection, sanitize trusted extension/settings content, or promise sandbox writes through the read-only opt-in.

## Approved version and toolchain contract

The exact repository-managed Pi package/version is an approved decision, not a remaining execution gate.

| Tool | Required version | Authority and bootstrap contract |
| --- | --- | --- |
| Node | 24.19.0 | Existing Dev Container image/assertions; assert the built-in template or reproducibly provision in the privileged system phase. |
| pnpm | 11.20.0 | Root `package.json`; assert or reproducibly provision, then run as the normal sandbox user. |
| Python | 3.14.4 | Existing Dev Container/API contract; assert or reproducibly provision in the privileged system phase. |
| uv | 0.12.2 | Existing Dev Container image/assertions; assert or reproducibly provision, then run as the normal user. |
| Pi | `@earendil-works/pi-coding-agent@0.84.1` | Add `tools/pi-version.txt`; all repository-controlled Dev Container and Sandbox installs/assertions consume or verify it. |
| Browser | locked Playwright Chromium | Install/prove Chromium by default; Firefox and WebKit are an explicit full-E2E opt-in. |

Cursor remains optional and separately evidenced even though the selected Pi pin meets its minimum version; the repository pin alone does not establish extension or credential compatibility.

## Files to add or modify

| Path | Change |
| --- | --- |
| `tools/pi-version.txt` | Add the single exact repository-managed authority, `@earendil-works/pi-coding-agent@0.84.1`. |
| `.sandbox/launch-pi.sh` | Add clean-worktree clone default, trusted direct and explicit attach paths, preflights, validated read-only user settings/extensions workspaces, sandbox-local wiring, and safe publication handling. |
| `.sandbox/bootstrap-pi.sh` | Add idempotent privileged system provisioning and normal-user Pi/dependency/browser provisioning with exact assertions. |
| `.sandbox/test-contract.sh` | Add fake-`sbx` RED/GREEN contracts for lifecycle, refusal paths, credentials, policies, ports, cleanup, and output secrecy. |
| `.sandbox/smoke-test.sh` | Add authorized disposable live evidence with unique ownership, traps, baselines, recovery, isolation probes, and deterministic teardown. |
| `.gitignore` and/or `.dockerignore` | Ignore only known generated Sandbox helper state; never hide credentials as a safety mechanism. |
| `.devcontainer/setup.sh` and `.devcontainer/smoke-test.sh` | Consume/assert the single approved Pi authority and preserve Dev Container provisioning. |
| `package.json` | Add `sandbox:test` for fake-`sbx` contracts only; add no lifecycle hook or `sbx` dependency. |
| `docs/design-docs/0002-docker-sandbox-pi-runtime.md`, `docs/design-docs/README.md` | Record/index the runtime, boundaries, exact version decision, connections, and deferred alternatives. |
| `docs/references/docker-sandbox-pi.md`, `docs/references/README.md` | Add/index the operational reference. |
| `docs/references/environment-variables.md` | Document launcher variables only if implementation introduces them. |
| `docs/ARCHITECTURE.md` | Record validated Sandbox-to-host and nested-Compose connections. |
| `README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `.devcontainer/README.md` | Surface and contrast the optional route without weakening existing paths. |
| `docs/coding-agent-harness/README.md`, `docs/coding-agent-harness/configuration.md` | Document version/configuration/authentication ownership. |

Implementation may narrow the map when an existing canonical document covers a requirement, but it must not add a runtime connection, credential mechanism, or product choice without approval.

## Steps

- [ ] **1. Clear approval gates and capture baselines.**
  - Confirm the approved `@earendil-works/pi-coding-agent@0.84.1` authority is stated consistently and will be written to `tools/pi-version.txt`; there is no remaining Pi-version selection gate.
  - Require exact `sbx` 0.38.0 installed help and disposable live evidence proving template resolution, clone source selection, attach behavior, Pi startup, value-free secret inventory/removal, effective policy inventory/check/removal, port inventory/unpublish, copy/recovery, and sandbox lifecycle/removal syntax before committing commands. Any version or behavior mismatch blocks implementation.
  - Record name-only sandbox, global/named secret, effective policy, listener, template-tag/export, and staging-worktree/remote baselines. Refuse live work if existing broad credentials or policy can contaminate the test.
  - Acceptance: the scout report begins `READY`; otherwise it begins `BLOCKED`, identifies the unresolved gate, and all downstream writers do nothing.

- [ ] **2. Write failing synthetic contracts.**
  - Use a fake `sbx` that captures arguments without credentials, Docker login, network, or host Pi state.
  - Cover unique creation and collision refusal; dedicated clean worktree selection; tracked-only and symlink preflight; sentinel `.env`, `.npmrc`, `.pi/npm`, `.pi/git`, `auth.json`, `node_modules`, `.venv`, private-key, directory, and escape refusals; and absence from the expected clone source.
  - Cover direct warnings, omission of an invented direct flag, explicit attach restrictions, exact built-in template selection, custom-template prohibition, and creation versus attach publication.
  - Cover disabled-by-default user Pi opt-in; validation of a regular non-symlink settings file and directory non-symlink extensions root; two separate read-only workspace exposures; sandbox-local Pi wiring; whole-agent-directory exclusion; structural top-level legacy `apiKeys` rejection without value output; and refusal/failure of settings writes while enabled. Prove settings/extensions are not packages-only projected, sanitized, or copied file by file, and document concurrent host rewrites as unsupported.
  - Cover value-free global/named secret inventory, contamination refusal, stdin-only creation, intended scoped names, removal/absence, effective-policy positive/negative checks, rule-ID cleanup, nested-network probes, and baseline comparison.
  - Acceptance: contracts fail for missing behavior for the intended reason and `pnpm sandbox:test` runs only this synthetic suite.

- [ ] **3. Implement lifecycle and reproducible bootstrap.**
  - Sequence: generate and collision-check a name; create the tracked-only staging worktree; require exact 0.38.0; create a named `shell` sandbox with the approved built-in template and mode; optionally expose only validated user settings/extensions as separate read-only workspaces and wire them into sandbox-local Pi paths; configure temporary bootstrap egress; run root execution only for OS packages; run pnpm, uv, pinned Pi, caches, Linux-native global packages, and browser work as the normal user with sandbox-local writable package/Git state; verify versions/Nx/Python/Chromium; then start Pi using only lifecycle commands proven by exact 0.38.0 help and live evidence in Step 1.
  - Run equivalents of `pnpm install --frozen-lockfile` and `uv sync --project projects/api --locked`. Install/prove Chromium by default; make Firefox/WebKit opt-in.
  - Run bootstrap twice and compare lockfiles, tracked/generated state, ownership, versions, and cache locations. No tracked state changes and no root-owned user files are allowed.
  - Implement a separately validated attach flow with no creation-only flags and no silent sandbox reuse.
  - Acceptance: fake contracts pass; repeated bootstrap is idempotent; `shell-docker` is explicit; the exact Pi pin is asserted; no custom snapshot or host auth/package/Git state is used; the optional settings/extensions exposure is read-only and excludes the rest of the host Pi agent directory.

- [ ] **4. Enforce source, input, credential, and effective-egress boundaries.**
  - Refuse prohibited source sentinels before `sbx` and prove their absence from `/run/sandbox/source` when live. Describe direct mode as full selected-checkout mutation.
  - When explicitly enabled, validate the host settings file and extensions directory types without following symlinks, expose each as its own read-only Sandbox workspace, and wire them into sandbox-local Pi paths. Structurally reject top-level legacy `apiKeys` without printing values. Treat all other content as user-inspected trusted readable/executable input; do not sanitize it, project only packages, or copy extensions individually. Prove global packages install Linux-native copies into sandbox-local writable package/Git state and settings writes fail or require disabling the opt-in.
  - Inventory global and sandbox secret names before provider smoke; refuse contamination; accept approved secret-manager stdin only; prove intended names; remove and prove absence without values. State upstream revocation separately.
  - Inspect all applicable policy, reject broad active allows, positively check approved destinations, negatively check unapproved hosts/ports/local ranges/wildcards, record local rule IDs, and prove rule cleanup.
  - Acceptance: no secret value appears in repository files, helper arguments/output, or VM files; only the proxy store intentionally retains a supplied scoped secret until explicit removal.

- [ ] **5. Verify Docker, ports, and host service isolation.**
  - In `shell-docker`, prove the socket/daemon is VM-local and cannot see host contexts, containers, or images. Run blocked probes from the outer shell and nested disposable container.
  - Verify nested Compose and two publication layers. Publish no outer ports by default; never publish VM 5432 by default; use discovered ephemeral loopback-only host mappings for requested 4200/8000.
  - Test the llama.cpp address/policy pairing only when an approved host service is available, including positive and negative policy checks.
  - Acceptance: Docker/Compose and endpoints work only in exercised cases, nested egress remains constrained, and no claim exceeds evidence.

- [ ] **6. Produce substantial living documentation.**
  - Add the design record and indexed operational reference; update architecture, onboarding, agent policy, Dev Container comparison, Pi ownership, and any introduced environment variables.
  - Document the exact verified 0.38.0 CLI lifecycle, clean staging worktree, trusted direct boundary, attach contract, trusted read-only user settings/extensions workspaces and exclusions, sandbox-local Pi/package/Git state, top-level legacy `apiKeys` refusal, read-only write/concurrency behavior, proxy-versus-VM credentials, unsupported enterprise matrix, effective egress, Docker isolation, ports, host-side recovery, and teardown.
  - Acceptance: readers can choose a runtime, preserve work, and clean resources without interpreting the Dev Container or ordinary checkout as isolated.

- [ ] **7. Gather disposable evidence, review, and validate.**
  - Generate a unique name, prove it is unused, record invocation-owned resources, and install `EXIT`, `INT`, and `TERM` traps. Never attach to or remove a pre-existing sandbox; prohibit `sbx reset`, bulk removal, global secrets, and global/wildcard rules.
  - Use disposable prohibited-file sentinels to prove refusal or clone-source absence. Exercise bootstrap twice, exact pinned Pi startup, user-settings/extensions opt-in validation/read-only wiring/write refusal, recovery to the host, policy positive/negative checks, scoped-secret inventory/cleanup, nested Docker isolation/egress, Compose, and optional loopback ports.
  - Run Nx sync/discovery and applicable lint, typecheck, test, and build targets; run locked Python sync/API tests and a Chromium launch check. Keep the full three-browser suite opt-in.
  - Run parallel security/reproducibility reviews, one serial fix pass, and final validation. Check `sbx template ls --json` and the filesystem against baseline for unexpected custom tags or tar exports.
  - Acceptance: applicable checks pass; unavailable cases are explicit gaps; no blocker remains; and post-teardown inventories match baseline.

## Deterministic teardown and recovery

The smoke helper preserves work first, then performs provider logout and upstream revocation when applicable; removes only invocation-owned sandbox-scoped secrets and checks name-only absence; removes recorded local policy rule IDs and checks absence; unpublishes and checks listeners; stops/removes nested Compose resources; removes the created sandbox; removes the generated staging worktree and `sandbox-<name>` remote; and finally compares sandbox, secret-name, policy, listener, custom-template/export, worktree, and remote inventories with baseline. Signal traps follow the same order. Failure in one cleanup stage is reported and must not authorize broad cleanup.

Deleting a proxy secret, VM, worktree, or remote does not revoke an upstream API key or OAuth grant. Recovery uses the host-side generated remote or live-proven copy interface; upstream pushes happen from the host after review.

## Verification

Run from the repository root. Exact `sbx` flags must come from installed exact 0.38.0 help plus disposable live evidence and committed, smoke-proven helpers; do not substitute guessed syntax.

```bash
bash -n .sandbox/launch-pi.sh .sandbox/bootstrap-pi.sh .sandbox/test-contract.sh .sandbox/smoke-test.sh
pnpm sandbox:test

# Eligible, logged-in, explicitly authorized hosts only.
.sandbox/smoke-test.sh

docker compose config --quiet
pnpm exec nx sync:check
pnpm exec nx affected -t lint typecheck test build --base=origin/main --parallel=3
pnpm exec markdownlint-cli2 \
  README.md CONTRIBUTING.md AGENTS.md .devcontainer/README.md \
  docs/ARCHITECTURE.md docs/design-docs/0002-docker-sandbox-pi-runtime.md \
  docs/references/README.md docs/references/docker-sandbox-pi.md \
  docs/coding-agent-harness/README.md docs/coding-agent-harness/configuration.md \
  docs/prompts/2026_08_07_1748-integrate-docker-sandboxes/README.md
git diff --check
git status --short
```

The synthetic suite is mandatory. Live evidence records exact `sbx` 0.38.0 and pinned Pi package/version, host OS/architecture, virtualization eligibility, resolved template, workspace mount layout including optional read-only settings/extensions, effective policy, nested-daemon result, provider/account/organization matrix, ports, cleanup inventories, and cases not run. Generic CI runs only `pnpm sandbox:test`; it never launches `sbx`.

## Documentation impact

This change adds an optional agent runtime, security boundary, credential paths, Sandbox-to-host connection, and nested-Compose/two-level publication. Substantial technical-writer work is required in the mapped living documents after implementation. This canonical plan remains the planning archive.

## Risks and recovery

- **Clone contamination:** the ordinary checkout contains ignored state. The clean staging worktree, fail-closed preflight, and live sentinel probes are required; lack of clone-source control blocks support.
- **Direct exposure:** direct mode allows full selected-checkout reads and mutation, including credentials, hooks, caches, and ignored state. It is a trusted explicit opt-in, not an isolation claim.
- **Credential contamination:** existing global proxy or registry credentials can satisfy a request unexpectedly. Provider smoke is refused when value-free inventory cannot exclude that path.
- **Persistent credentials:** proxy entries and VM OAuth state have different ownership and cleanup. Local deletion does not revoke upstream credentials.
- **Effective-policy breadth:** organization/profile/global rules or nested Docker could broaden egress. Unsupported effective isolation blocks an isolation claim even if local rules look exact.
- **Lost work/resources:** VM removal destroys clone work, while policies, proxy entries, listeners, worktrees, remotes, or exports may persist separately. Trap-driven owned-resource cleanup and host-side recovery are mandatory.
- **Trusted user Pi input:** opted-in settings/extensions are readable/executable and may contain commands, secrets, or host-only paths. Users must inspect them; structural top-level `apiKeys` rejection is not sanitization. Read-only workspaces prevent supported sandbox configuration writes, and concurrent host rewrites are unsupported.
- **Native package drift:** global package declarations are reinstalled as Linux-native copies in sandbox-local writable package/Git state rather than reusing host artifacts; registry/network availability and package install behavior remain evidence-bounded.
- **Version and provider drift:** `sbx`, Pi, templates, provider flows, and extensions change independently. Evidence is exact-version and exact-matrix only.

## Assumptions requiring approval

- The repository-managed Pi authority is approved as `@earendil-works/pi-coding-agent@0.84.1`; Dev Container setup/smoke and Sandbox bootstrap consume or assert it. Cursor remains optional and separately evidenced.
- The explicit trusted user Pi opt-in exposes only validated regular non-symlink `~/.pi/agent/settings.json` and directory non-symlink `~/.pi/agent/extensions` as separate read-only workspaces. All content is user-inspected trusted input; top-level legacy `apiKeys` is rejected structurally without value output; whole-agent mounting, packages-only projection, per-file extension copying, and concurrent host rewrites are excluded.
- Docker Sandboxes is accepted as an optional manual runtime; host development and the trusted Dev Container remain supported.
- Clone default means a generated tracked-only staging worktree, not the user's ordinary checkout. Direct mode remains an explicit trusted opt-in.
- Built-in `shell`/`shell-docker` selection, clean clone-source control, Pi startup, nested-daemon isolation, and exact cleanup remain unsupported until exact 0.38.0 help and disposable live evidence pass.
- Host-stored sandbox-scoped proxy secrets and explicit sandbox-local Pi OAuth are allowed only with their distinct inventory, cleanup, persistence, and revocation contracts.
- Codex Enterprise, GitHub Copilot Enterprise, and Anthropic Enterprise remain unsupported/unverified until the full approved evidence matrix is recorded.
- The host llama.cpp connection is approved only if exact address/policy pairing and negative checks pass; otherwise it remains unsupported.

---
status: approved
---

# Replace Plannotator with saved pi-subagents plan workflows

## Goal

Replace Plannotator with an editor-reviewed Markdown planning workflow that uses `pi-subagents` for planning and execution. Each canonical plan has one matching, plan-specific saved chain for repeatable execution and auditability.

## Context

Plannotator has been intentionally uninstalled. The repository already has canonical plan archives in `docs/prompts/`, the `save-approved-plan` skill, and `pi-subagents` roles and saved-chain support. The replacement must use those capabilities rather than build a second workflow engine.

This draft supersedes the earlier controller proposal. It intentionally removes the custom extension, RPC adapter, locks, checkpoint protocol, hash protocol, and automatic cross-session recovery. Those mechanisms either duplicate `pi-subagents` or exceed its public integration boundary.

## Workflow

### Paths and naming

A saved-plan pair uses the same timestamp and slug:

```text
docs/prompts/YYYY_MM_DD_HHMM-slug/README.md
.pi/chains/saved-plans/YYYY_MM_DD_HHMM-slug.chain.json
```

A plan-specific chain has a runtime name such as `saved-plan-YYYY_MM_DD_HHMM-slug`. Its native `name` and `description` identify the canonical plan path and state that it is plan-specific. Reusable generic chains, if needed, live under `.pi/chains/workflows/`.

The plan's `## Workflow` section links to its exact [saved chain](../../../.pi/chains/saved-plans/2026_07_24_1903-replace-plannotator-with-subagent-workflows.chain.json) before the draft is recorded. `.pi/chains/saved-plans/` is reserved for plan-specific execution artifacts: a chain there is meant to run only for its linked, user-approved, registered plan. A draft chain may be prepared and reviewed before registration, but the parent must not run it until `status: approved` and the plan index records it. The chain remains discoverable, so approval is a user and parent-agent workflow rule rather than a technical enforcement boundary.

### Draft, approval, and execution lifecycle

1. The parent optionally gathers read-only context with `scout` or `context-builder`, then uses `planner` to prepare the canonical Markdown draft and matching saved chain. The parent remains the only writer during draft creation.
2. The parent runs `record-plan-draft <canonical-path>`. It validates the canonical path, `status: draft`, required plan structure, and exact saved-chain link; it then adds or idempotently updates one `📝 draft` row in `docs/prompts/README.md`. It does not start implementation or infer approval.
3. The user reviews the Markdown plan and matching chain in an editor. Approval is explicit: the user either changes the frontmatter to `status: approved` or tells the parent to approve it, in which case the parent records `status: approved` in the canonical Markdown file.
4. The parent runs `save-approved-plan <canonical-path>`. It revalidates the canonical path, `status: approved`, links, and exactly one matching draft row, then promotes that row to `⬜ not started`. It never starts the chain.
5. Only an explicit user request starts implementation. The parent runs the matching native chain with `/run-chain <name>` and follows its progress through native async status and artifacts.
6. Chains keep mutations serial: one worker or fixer writes at a time. They may fan out only read-only context, review, or validation work. The parent reviews chain results, accepts fixes, and updates only completed plan checkboxes and the index status (checkboxes should be updated as the plan progresses in real-time).
7. Native `status` and `resume` support normal same-session recovery. If a later session cannot determine whether an earlier writer is still active, it stops and asks for manual resolution rather than launching another writer.

## Decisions and non-goals

### Decisions

- Canonical plans remain ordinary Markdown at `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md` with frontmatter `status: draft` or `status: approved`.
- `.pi/chains/saved-plans/` is reserved for plan-specific execution artifacts. A chain there is eligible to run only after its linked plan has explicit user approval and a registered plan-index row; agents must find and read that canonical plan first.
- `record-plan-draft` records a draft row. `save-approved-plan` retains its name and registers only an explicitly approved plan by promoting that same row; neither procedure starts implementation.
- `pi-subagents` remains the orchestration mechanism. The parent owns scope, decisions, approval handling, result synthesis, plan progress, and follow-up work.
- Use one writer in the shared checkout. Parallel work is read-only unless isolated worktrees are deliberately approved.
- TDD, independent review, documentation impact, and completion checks remain project policies. A saved chain prompts and sequences that work; it does not replace parent judgment.

### Non-goals

- Do not recreate Plannotator's browser UI, annotations, visual diffing, or execute-on-save behavior.
- Do not add a project extension, custom RPC adapter, custom chain parser, controller, lock store, checkpoint protocol, hash protocol, or generic workflow language.
- Do not claim that chain discovery, task prompts, or native artifacts enforce approval, read-only work, or cross-session writer exclusivity.
- Do not add automatic recovery when ownership of a previous writer is ambiguous.

## Approach

Use native `pi-subagents` roles and saved-chain semantics:

1. A parent-facing planning prompt or procedure invokes the builtin `planner` after any needed read-only context work.
2. The planner produces a canonical plan draft and a compact matching chain. A typical chain performs context, one serial implementation/TDD writer, optional parallel fresh reviews, one serial fix writer, documentation, and final validation.
3. `record-plan-draft` and `save-approved-plan` provide the two explicit lifecycle gates. They validate repository conventions and update the public plan index; execution remains a separate, explicit parent action.
4. The parent follows the existing normal or risky delegation workflow for the approved scope. It updates checkboxes only after reviewing actual chain evidence and updates the index to `🟡 in progress`, `🟢 partial`, or `✅ completed` as appropriate.

## Files to modify, remove, or add

| Path | Change |
| --- | --- |
| `.pi/chains/README.md` | Document the two chain namespaces and require explicit user approval plus plan registration before a plan-specific chain is run. |
| `.pi/chains/saved-plans/README.md` | Document that this namespace is reserved for plan-specific execution chains that run only for linked, user-approved, registered plans. |
| `.pi/chains/saved-plans/` | Add the dedicated namespace for plan-specific chains that run only for linked, user-approved, registered plans. Move and replace the current controller-oriented chain with a compact native saved chain for this plan; future plans add one matching chain here. |
| `.pi/chains/workflows/` | Reserve this namespace for reusable generic chains; do not place plan-specific chains here. |
| `.agents/skills/record-plan-draft/SKILL.md` | Add the parent-facing draft-recording procedure: validate the draft, exact chain link, and one `📝 draft` index row; never infer approval or start work. |
| `.agents/skills/save-approved-plan/SKILL.md` | Remove Plannotator assumptions. Validate explicit approval and promote the existing matching draft row to `⬜ not started`; never create a duplicate row or start execution. |
| `.pi/prompts/draft-plan.md` | Add concise parent-facing guidance for using `pi-subagents` context/planner roles to create a canonical draft and matching saved chain. |
| `.pi/plannotator.json` | Delete if present. The current checkout has no such configuration file, so do not create one merely to delete it. |
| `.pi/settings.json` | Remove a stale Plannotator package only if one exists; otherwise leave the existing `pi-subagents` configuration unchanged. |
| `AGENTS.md`, `docs/coding-agent-harness/{workflows,delegation,configuration,skills,extensions}.md`, `docs/prompts/README.md`, `docs/standards/documentation.md` | Replace Plannotator references with the draft → record → editor approval → register → explicit native-chain execution lifecycle. Add the `📝 draft` index status and document the saved-plan chain namespace. |

## Reuse

- Reuse builtin `pi-subagents` `scout`, `context-builder`, `planner`, `worker`, `reviewer`, and `oracle` roles as appropriate.
- Reuse native saved `.chain.json` discovery, sequential and parallel stages, named outputs, output schemas, async status, artifacts, and resume behavior.
- Reuse the existing canonical archive, checkbox, and lifecycle-index rules from `docs/prompts/README.md` and `save-approved-plan`.
- Reuse the parent-owned, single-writer delegation policy in `docs/coding-agent-harness/delegation.md`.

## Steps

- [x] **1. Define and document the approved saved-plan chain convention.**
  - Add `.pi/chains/saved-plans/` and `.pi/chains/workflows/` conventions. Document in `.pi/chains/README.md`, `.pi/chains/saved-plans/README.md`, `AGENTS.md`, plan-index documentation, and delegation guidance that `.pi/chains/saved-plans/` is reserved for plan-specific chains that run only for linked, user-approved, registered plans.
  - Replace this plan's existing controller-oriented chain with a compact native chain at its matching `saved-plans` path, then add the exact chain link to this plan's `## Workflow` section before recording it.
  - Acceptance: the chain parses, has the matching timestamp/slug and canonical plan path in its native metadata, and the root/saved-plan chain READMEs plus policy documentation require the parent to verify user approval and plan registration before `/run-chain`.

- [x] **2. Add the draft and approval registration procedures.**
  - Add `record-plan-draft` and revise `save-approved-plan` for explicit editor approval, one-row lifecycle transitions, and no execution side effects.
  - Acceptance: a valid draft creates or updates exactly one `📝 draft` row; only an explicitly approved draft promotes that same row to `⬜ not started`; saving, recording, and registration do not start a chain.

- [x] **3. Add parent-facing pi-subagents planning guidance.**
  - Add concise draft-plan guidance that uses context/planner roles to create the canonical draft and matching saved chain, without introducing a custom agent, controller, or runtime mode.
  - Acceptance: the guidance identifies the canonical paths, editor-review gate, parent ownership, and single-writer/read-only-fan-out rules.

- [x] **4. Migrate configuration and living documentation.**
  - Remove remaining Plannotator workflow assumptions, delete stale configuration only when present, add the draft status legend, and document the saved-plan namespace and lifecycle.
  - Acceptance: documentation matches the skills and native `pi-subagents` workflow; tracked-content search finds no stale Plannotator references except intentional migration history.

- [x] **5. Verify the lifecycle with deterministic documentation and command checks.**
  - Exercise draft creation, draft recording, explicit approval, registration, and an explicit native-chain start using a controlled example or fixture. Confirm that an unapproved or unregistered chain is not started by the procedures.
  - Acceptance: Markdown links and chain JSON validate; the index contains one correct row through every lifecycle transition; no runtime artifacts are staged.

## Verification

1. Validate each saved chain with `jq empty` and verify that its name, description, canonical plan path, and Markdown link use the same timestamp and slug.
2. Exercise `record-plan-draft` and `save-approved-plan` against valid, unapproved, duplicate-row, and mismatched-chain fixtures or controlled examples.
3. Confirm that only an explicit parent `/run-chain <name>` request starts implementation and that the parent verifies the linked plan is user-approved and registered first; draft recording and approval registration must have no execution side effect.
4. Validate Markdown links and search tracked content for stale Plannotator references, excluding intentional migration history.
5. Run the relevant documentation checks, builtin review, Lens diagnostics for edited source, and `pnpm exec nx affected -t lint test --base=origin/main --parallel=3` when applicable.
6. Confirm `git status --short` contains only intended documentation, skill, configuration, and saved-chain changes; do not stage `.pi-subagents/` runtime artifacts.

## Documentation impact

This changes the developer planning and execution workflow. Update the root policy, plan archive/index documentation, skills documentation, configuration and extension guidance, and delegation workflow in the same change. No service topology update is required because this adds no network dependency.

## Risks and recovery

- **Direct chain execution:** saved chains remain discoverable. The parent verifies that the linked plan is user-approved and registered before running a chain from `.pi/chains/saved-plans/`; document this as a workflow rule rather than technical enforcement.
- **Duplicate draft rows:** make `record-plan-draft` idempotent and reject contradictory rows.
- **Plan/chain mismatch:** require matching timestamp/slug, canonical-path metadata, and the exact Markdown link before recording or registration.
- **Interrupted work:** use native status and resume when the owner is known. Pause and ask for manual resolution when cross-session ownership is ambiguous.
- **Scope expansion:** workers escalate product, architecture, security, or scope decisions to the parent rather than changing the approved plan.

## Assumptions requiring approval

- A `📝 draft` row is an acceptable public record before approval.
- A project `record-plan-draft` skill/procedure is sufficient; no extension command is required.
- The parent may record `status: approved` in the canonical Markdown when the user explicitly approves in conversation.
- Per-plan saved chains are valuable for repeatability and auditability, but their native metadata and optional human review are sufficient; a mandatory digest or immutable execution protocol is not needed.

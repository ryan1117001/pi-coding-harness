# Pi workflows

This page links the mandatory workspace policy to the detailed Pi operating guides. Start with [`AGENTS.md`](../../AGENTS.md), then read the nearest project `AGENTS.md` before changing project files.

## Plan and execute

[`../prompts/README.md`](../prompts/README.md) is the detailed source for plan archives, status values, approval, registration, and progress updates. For a non-trivial change, the parent uses `pi-subagents` read-only context work and `planner` as needed, then creates the canonical plan and matching saved chain described there.

The parent runs `record-plan-draft`, waits for editor-reviewed explicit approval, and then runs `save-approved-plan`. Neither command starts work. Only a separate explicit user request starts implementation; the parent runs the registered matching chain and updates completed checklist items and index status from actual evidence. If a plan begins elsewhere, stop and ask rather than creating a second plan.

### Saved plan chains

[`.pi/chains/saved-plans/`](../../.pi/chains/saved-plans/README.md) is reserved for plan-specific execution chains. Run one only when its linked canonical plan has explicit user approval and is registered in [`docs/prompts/README.md`](../prompts/README.md). The parent verifies these conditions before `/run-chain`; chain discovery does not enforce them.

```mermaid
flowchart LR
  D[Draft and matching chain] --> R[record-plan-draft]
  R --> E[Editor review]
  E --> A[Explicit approval]
  A --> S[save-approved-plan]
  S --> X[Explicit user request]
  X --> I[Run saved chain and update progress]
```

## Delegate

Load `pi-subagents` before orchestrating. The parent owns delegation, synthesis, final decisions, and follow-up work; ordinary children receive a concrete task and do not orchestrate more children.

Use [delegation.md](delegation.md) to select a role, choose a workflow, and apply single-writer and fresh-review guardrails. Assess documentation impact for every behavior, API, configuration, architecture, or workflow change; delegate substantial, cross-file, or user-facing documentation work to `technical-writer`.

## Prompt and MCP use

The repository prompt is `/architecture-check`; use it when frontend boundaries could change. Use `nx-run-tasks` or direct Nx commands for test and lint requests.

The shared [`.mcp.json`](../../.mcp.json) declares DaisyUI with `directTools: true` and the workspace-pinned Nx MCP server. Cached DaisyUI tools are callable directly; use the MCP proxy for discovery when direct metadata is unavailable. Use Nx MCP for workspace-aware guidance and the pinned Nx CLI for deterministic commands.

## Review and completion

For implementation work:

1. Follow RED, GREEN, REFACTOR under the root and project `AGENTS.md` rules.
2. Run focused tests while editing.
3. Run the builtin reviewer and resolve accepted blocking findings.
4. Run Lens diagnostics on edited source and resolve new blockers.
5. Run `pnpm exec nx affected -t lint test --base=origin/main --parallel=3`.
6. Run `/architecture-check` when frontend boundaries could change.
7. Assess documentation impact, update the required documentation and architecture record, validate changed links, and use `technical-writer` when the documentation work is substantial, cross-file, or user-facing.

Report commands, outcomes, and residual risk; never imply a check ran when it did not.

See also: [Pi configuration](configuration.md), [extensions](extensions.md), and [agent skills](skills.md).

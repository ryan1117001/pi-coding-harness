# Pi workflows

## Plan and execute

Use Plannotator for non-trivial changes:

1. Start plan mode with `/plannotator` or `pi --plan`.
2. Create the first draft directly at `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md`. The same file remains the working plan through every revision and approval.
3. Submit it through Plannotator's browser review.
4. After approval, load `save-approved-plan`. It validates the path and adds the index row in `docs/prompts/README.md`; it never copies or rewrites the plan.
5. Implement the approved checklist and update only the index status as work progresses.

If a plan begins at a non-canonical path, stop and ask rather than creating a second plan.

## Delegate

`pi-subagents` supplies the overlapping general roles:

- `scout` for local reconnaissance.
- `researcher` for sourced external research.
- `planner` for delegated implementation planning.
- `worker` for implementation.
- `reviewer` for code/plan review; the project override preloads `codebase-analysis`.
- `oracle` for decision-consistency and second opinions.
- `context-builder` and `delegate` for broader handoffs when their distinct contracts apply.

The project adds `technical-writer` for substantial documentation. Keep one writer in a checkout. Use fresh read-only reviewers in parallel, then let the parent or one designated worker apply accepted fixes. Use isolated worktrees only for clean-tree parallel tasks that may write overlapping files.

## Prompt and MCP use

The only repository prompt is `/architecture-check`; test and lint requests use the `nx-run-tasks` skill or direct Nx commands. Lens formats changed files and supplies diagnostics, so there is no format command or lifecycle hook.

The DaisyUI MCP server remains in `.mcp.json`. Use the adapter's search/describe flow before a tool call; the server connects lazily.

## Review and completion

For implementation work:

1. Follow RED, GREEN, REFACTOR under the root and project `AGENTS.md` rules.
2. Run focused tests while editing.
3. Use the builtin reviewer for an evidence-backed diff review when the change is non-trivial.
4. Run Lens diagnostics on edited source and resolve new blockers.
5. Run `pnpm exec nx affected -t lint test --base=origin/main --parallel=3`.
6. Run `/architecture-check` when frontend boundaries could change.
7. Confirm docs, architecture, and the plan index describe the final state.

Report commands, outcomes, and residual risk; never imply a check ran when it did not.

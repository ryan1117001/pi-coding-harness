# Draft a plan with pi-subagents

Use this prompt for a non-trivial change that needs an editor-reviewed plan.

1. Keep the parent responsible for scope and decisions. Use `scout` or `context-builder` for read-only context, then use `planner` to prepare the draft.
2. Create the canonical Markdown draft at `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md` with frontmatter `status: draft`.
3. Create one matching native chain at `.pi/chains/saved-plans/YYYY_MM_DD_HHMM-slug.chain.json`. Its name and description identify the canonical plan path and state that it is plan-specific. The plan's `Workflow` section links to that exact chain.
4. The parent uses `record-plan-draft` to validate the draft and create or retain one `📝 draft` index row. This does not approve the plan or start implementation.
5. The user reviews the Markdown plan and chain in an editor. After explicit user approval, the parent records `status: approved` if needed and uses `save-approved-plan` to promote the existing row to `⬜ not started`.
6. Only an explicit user request starts implementation. The parent verifies approval and registration, then runs the matching chain with `/run-chain <name>`.

Keep one writer at a time. Context, review, and validation fan-out are read-only; a parent-owned worker or fixer applies accepted changes serially. Stop and ask the user when scope, product, architecture, or security decisions are not approved.

---
name: save-approved-plan
description: Validate and register an explicitly approved canonical Markdown plan. Use after draft recording and before implementation; never copy or move the plan, or start its chain.
---

# Register an approved plan

Use this procedure after the user explicitly approves a canonical Markdown draft. It promotes that draft's existing `📝 draft` row in [`docs/prompts/README.md`](../../../docs/prompts/README.md) to `⬜ not started`. Registration never executes the matching chain.

## Required shape

```text
docs/prompts/
  README.md
  YYYY_MM_DD_HHMM-brief-description/
    README.md
.pi/chains/saved-plans/
  YYYY_MM_DD_HHMM-brief-description.chain.json
```

- `README.md` is the canonical plan entry point. Its dated directory may contain committed planning-time Markdown, HTML, and image artifacts, including subdirectories.
- Supporting artifacts capture planning-time evidence and decisions. They must not contain credentials, dependencies, generated build output, or implementation logs.
- The canonical plan uses `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md`, has frontmatter `status: approved`, and links from `Workflow` to its exact matching saved chain.
- The matching chain name and description identify the same canonical plan timestamp and slug.
- Approved prose, scope, step order, and supporting artifacts remain unchanged; completed implementation-step checkboxes are the only permitted post-approval plan edits.

## Procedure

1. Confirm explicit user approval in the conversation or `status: approved` in the canonical plan. If neither exists, stop.
2. Read the plan, matching saved chain, and plan index. Validate the canonical path, required plan structure, exact chain link, and matching timestamp/slug in chain metadata.
3. Find index rows for the exact canonical plan path. Require exactly one `📝 draft` row. If no row, more than one row, or a different status exists, stop and ask the parent to resolve the lifecycle conflict.
4. Promote that row to `⬜ not started` without creating a duplicate row. Recheck that the index link resolves.
5. Begin implementation only after registration and only after a separate explicit user request. The parent then decides whether to run the matching saved chain.
6. As each implementation step completes, change that exact checklist item from `- [ ]` to `- [x]` in the registered plan and update the index status to `🟡 in progress`, `🟢 partial`, or `✅ completed`.
7. Before completion, promote durable behavior, interface, configuration, architecture, and workflow conclusions into living documentation rather than leaving the archive as the sole record.

## Prohibited

- Registering an unapproved draft or inferring approval.
- Starting `/run-chain`, implementation, or modifying implementation checkboxes during registration.
- Creating a duplicate index row or silently resolving contradictory lifecycle rows.
- Copying, moving, rewriting, splitting, or reformatting the canonical plan or its planning artifacts.
- Adding credentials, dependencies, generated output, implementation logs, or unrelated material to a dated plan directory.

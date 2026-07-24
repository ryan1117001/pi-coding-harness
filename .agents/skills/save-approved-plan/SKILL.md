---
name: save-approved-plan
description: Validate and register the canonical plan file immediately after Plannotator approval. Use before implementation; never copy or move the approved plan, and track execution by checking off completed steps.
---

# Register an approved Plannotator plan

Plannotator uses the archived plan as its working file from the first draft onward. After approval, register that same file in [`docs/prompts/README.md`](../../../docs/prompts/README.md) before changing implementation files.

## Required shape

```text
docs/prompts/
  README.md
  YYYY_MM_DD_HHMM-brief-description/
    README.md                 # approved plan and index target
    research.md               # optional planning artifact
    diagrams/
      tradeoffs.html          # optional planning artifact
      flow.png                # optional planning artifact
```

- `YYYY_MM_DD_HHMM` is the local authoring date and 24-hour time; use `0000` only when the time was unavailable when planning began.
- The slug is short, descriptive kebab-case.
- `README.md` is required and is the only approved plan entry point. The dated directory may also contain committed, plan-related supporting Markdown, HTML, and image artifacts, including subdirectories.
- Supporting artifacts capture planning-time evidence and decisions. They must not contain credentials, dependencies, generated build output, or implementation logs.
- Approved prose, scope, step order, and supporting artifacts remain unchanged; completed implementation-step checkboxes are the only permitted post-approval plan edits.

## Workflow

1. Read Plannotator's approved `planFilePath` and any supporting artifacts in its dated directory.
2. Validate that `planFilePath` already matches `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md`. Allow only plan-related supporting Markdown, HTML, and image artifacts beside it; do not require the directory to be otherwise empty.
3. If the plan path is not canonical or directory contents are unrelated, stop and ask the user how to proceed. Do not create a second copy, move the approved file, or silently normalize its content.
4. Add one row to `docs/prompts/README.md` if the exact plan is not already registered:

   ```markdown
   | [YYYY_MM_DD_HHMM-brief-description](YYYY_MM_DD_HHMM-brief-description/README.md) | ⬜ not started | One-sentence description of the approved outcome. |
   ```

5. Begin implementation only after the index link resolves.
6. As each implementation step is completed, change that exact checklist item in the registered plan from `- [ ]` to `- [x]`, then update the index status: `🟡 in progress`, `🟢 partial`, or `✅ completed`. Do not alter approved prose, scope, step order, supporting artifacts, or unchecked steps.
7. Before completion, review the plan and its artifacts for durable decisions, behavior, interfaces, configuration, architecture, or workflow guidance. Capture applicable conclusions in the appropriate living documentation rather than leaving the archive as the sole record.

## Prohibited

- Copying an approved plan from `PLAN.md`, `plans/`, a session message, or another temporary path.
- Rewriting, reformatting, summarizing, splitting, or changing approved prose, scope, or step order.
- Registering an unapproved draft.
- Starting implementation before registration.
- Adding execution notes or changing a checkbox before its corresponding implementation step is complete.
- Adding unrelated material, credentials, dependencies, generated output, or implementation logs to a dated plan directory.

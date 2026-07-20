---
name: save-approved-plan
description: Validate and register the canonical plan file immediately after Plannotator approval. Use before implementation; never copy, move, or rewrite the approved plan.
---

# Register an approved Plannotator plan

Plannotator uses the archived plan as its working file from the first draft onward. After approval, register that same file in [`docs/prompts/README.md`](../../../docs/prompts/README.md) before changing implementation files.

## Required shape

```text
docs/prompts/
  README.md
  YYYY_MM_DD_HHMM-brief-description/
    README.md
```

- `YYYY_MM_DD_HHMM` is the local authoring date and 24-hour time; use `0000` only when the time was unavailable when planning began.
- The slug is short, descriptive kebab-case.
- The dated directory contains only the approved `README.md`.
- The file content remains the exact text approved in Plannotator.

## Workflow

1. Read Plannotator's approved `planFilePath`.
2. Validate that it already matches `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md` and that the dated directory contains no other files.
3. If the path is not canonical, stop and ask the user how to proceed. Do not create a second copy, move the approved file, or silently normalize its content.
4. Add one row to `docs/prompts/README.md` if the exact plan is not already registered:

   ```markdown
   | [YYYY_MM_DD_HHMM-brief-description](YYYY_MM_DD_HHMM-brief-description/README.md) | ⬜ not started | One-sentence description of the approved outcome. |
   ```

5. Begin implementation only after the index link resolves.
6. Update only the index status as work proceeds: `🟡 in progress`, `🟢 partial`, or `✅ completed`. Do not edit the approved plan to record execution state.

## Prohibited

- Copying an approved plan from `PLAN.md`, `plans/`, a session message, or another temporary path.
- Rewriting, reformatting, summarizing, or splitting the approved plan.
- Registering an unapproved draft.
- Starting implementation before registration.
- Adding execution notes or changing checkboxes in the archived plan after approval.

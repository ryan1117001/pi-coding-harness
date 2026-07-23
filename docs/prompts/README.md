# docs/prompts/

Approved implementation plans. Plannotator creates each working plan directly at its canonical archive path and revises that same file through approval:

```text
docs/prompts/YYYY_MM_DD_HHMM-brief-description/README.md
```

The dated directory contains only that README. After approval, the `save-approved-plan` skill validates the path and registers it below before implementation. It never copies, moves, or splits the plan. As implementation steps complete, change their checkboxes from `- [ ]` to `- [x]` in the same plan; do not alter approved prose, scope, or step order. Update the index status separately.

## Status legend

- `⬜ not started`
- `🟡 in progress`
- `🟢 partial`
- `✅ completed`

## Plans in this repository

<!-- Example row:
| Plan | Status | Description |
| --- | --- | --- |
| [2026_01_01_0000-example](2026_01_01_0000-example/README.md) | ⬜ not started | One-line approved outcome. |
-->

| Plan | Status | Description |
| --- | --- | --- |

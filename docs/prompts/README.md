# docs/prompts/

Approved implementation plans and their planning-time artifacts. Plannotator creates each working plan directly at its canonical archive path and revises that same plan through approval:

```text
docs/prompts/YYYY_MM_DD_HHMM-brief-description/README.md
```

Each dated directory requires `README.md` as its approved plan, index target, and entry point. It may also contain committed, plan-related supporting Markdown, HTML, and image artifacts, including organized subdirectories. Link supporting artifacts from the plan when they inform its decisions. Keep only material that captures what was considered or planned at authoring time; do not store credentials, dependencies, generated build output, or implementation logs there. After approval, preserve the plan and its artifacts as the planning record; update only completed plan-step checkboxes in `README.md`.

After approval, the `save-approved-plan` skill validates the canonical plan path and registers it below before implementation. It never copies, moves, splits, or alters the plan archive. During implementation, promote durable decisions, behavior, interfaces, configuration, architecture, and workflow guidance from the plan and its artifacts into the appropriate living documentation. Update the index status separately.

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

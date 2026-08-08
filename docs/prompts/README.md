# docs/prompts/

Canonical Markdown implementation plans and their planning-time artifacts. The parent uses `pi-subagents` to prepare each draft directly at its canonical archive path, with one matching plan-specific chain:

```text
docs/prompts/YYYY_MM_DD_HHMM-brief-description/README.md
```

Each dated directory requires `README.md` as its canonical plan, index target, and entry point. It may also contain committed, plan-related supporting Markdown, HTML, and image artifacts, including organized subdirectories. Link supporting artifacts from the plan when they inform its decisions. Keep only material that captures what was considered or planned at authoring time; do not store credentials, dependencies, generated build output, or implementation logs there. After approval, preserve the plan and its artifacts as the planning record; update only completed plan-step checkboxes in `README.md`.

[`.pi/chains/saved-plans/`](../../.pi/chains/saved-plans/README.md) contains plan-specific execution chains. A draft chain may be reviewed with its plan, but the parent runs it only for its linked canonical plan after explicit user approval and registration in this index; chain discovery does not enforce those preconditions.

Use `record-plan-draft` to validate a `status: draft` plan and create or retain one `📝 draft` row. The user reviews the canonical Markdown plan and matching chain in an editor. After explicit approval, `save-approved-plan` validates the canonical path and matching chain, promotes that same row to `⬜ not started`, and never starts execution. During implementation, promote durable decisions, behavior, interfaces, configuration, architecture, and workflow guidance from the plan and its artifacts into the appropriate living documentation. Update the index status separately.

## Status legend

- `⬜ not started`
- `📝 draft`
- `🟡 in progress`
- `🟢 partial`
- `✅ completed`

## Plans in this repository

<!-- Example row:
| Plan | Status | Description |
| --- | --- | --- |
| [2026_01_01_0000-example](2026_01_01_0000-example/README.md) | ⬜ not started | One-line approved outcome. |
-->

| Plan                                                                                                                                 | Status         | Description                                                                                                                     |
| ------------------------------------------------------------------------------------------------------------------------------------ | -------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| [2026_07_24_1903-replace-plannotator-with-subagent-workflows](2026_07_24_1903-replace-plannotator-with-subagent-workflows/README.md) | ✅ completed   | Adopt editor-reviewed Markdown plans and plan-specific pi-subagents chains.                                                     |
| [2026_07_25_1758-documentation-revision](2026_07_25_1758-documentation-revision/README.md)                                           | ✅ completed   | Revise active repository-authored documentation for accuracy, concision, and human/agent usability.                             |
| [2026_08_05_2009-integrate-devcontainers](2026_08_05_2009-integrate-devcontainers/README.md)                                         | ✅ completed   | Add a reproducible Compose-backed Dev Container for trusted humans and coding agents.                                           |
| [2026_08_06_1521-opt-in-host-pi-extensions](2026_08_06_1521-opt-in-host-pi-extensions/README.md)                                     | ✅ completed   | Add explicit read-only host Pi extensions and settings to the trusted Dev Container while keeping credentials environment-only. |
| [2026_08_06_1934-modernize-and-simplify-template](2026_08_06_1934-modernize-and-simplify-template/README.md)                         | ✅ completed   | Upgrade packages with Nx's TypeScript 7/6 setup, repair validation, harden bootstrap code, and simplify documentation.          |
| [2026_08_07_1748-integrate-docker-sandboxes](2026_08_07_1748-integrate-docker-sandboxes/README.md)                                     | 🟢 partial     | Add an optional, evidence-bounded Docker Sandboxes runtime for Pi with isolated state, scoped credentials, and deterministic cleanup. |

# Pi extensions

Pi packages execute code with the user's permissions. The versions below were reviewed for this harness and are pinned in [`.pi/settings.json`](../../.pi/settings.json). Upgrade one package at a time and re-run the harness smoke checks.

## Retained packages

| Package | Version | License | Purpose and rationale |
| --- | --- | --- | --- |
| [`pi-web-access`](https://github.com/nicobailon/pi-web-access) | 0.13.0 | MIT | Web search, source extraction, GitHub inspection, and video/PDF retrieval. Supplies external research used by the researcher agent. |
| [`pi-readseek`](https://github.com/jarkkojs/readseek) | 0.8.0 | Apache-2.0; native dependency also LGPL-2.1-or-later | Anchored reads/edits, structural search, symbol navigation, and syntax validation. It replaces Pi's `read`, `edit`, `write`, and `grep` names to avoid duplicate file-tool surfaces. Syntax regressions block writes. |
| [`pi-lens`](https://github.com/apmantza/pi-lens) | 3.8.71 | MIT | Deferred formatting, LSP diagnostics, read guards, structural checks, and project analysis. Replaces custom formatting and end-of-turn diagnostic hooks. |
| [`pi-subagents`](https://github.com/nicobailon/pi-subagents) | 0.35.1 | MIT | Builtin scout, researcher, planner, worker, reviewer, oracle, context-builder, and delegate roles plus worktree-safe delegation. Optional packaged prompts and its explanatory skill are filtered because the registered tool and natural-language workflows already cover them. |
| [`pi-mcp-adapter`](https://github.com/nicobailon/pi-mcp-adapter) | 2.11.0 | MIT | Lazy MCP discovery through one proxy tool. It reads the standard [`.mcp.json`](../../.mcp.json), so no Pi-specific duplicate server definition is needed. |
| [`@plannotator/pi-extension`](https://github.com/backnotprop/plannotator) | 0.24.1 | MIT OR Apache-2.0 | File-based plan mode, browser approval, progress tracking, Markdown annotation, and visual code review. Project configuration writes plans directly to `docs/prompts/`. |

`pi-prompt-template-model` is not installed: Pi core loads project prompts and `pi-subagents` has a native prompt-workflow adapter. `pi-manage-todo-list` is not installed: its own documentation recommends a successor, while Plannotator already tracks approved-plan execution.

## Project settings

- Package versions use `npm:<name>@<exact-version>` so clean-checkout installation is deterministic.
- The reviewer override loads `codebase-analysis` and inherits the skill catalog, preserving evidence-backed review without a duplicate reviewer agent.
- The project-local `technical-writer` agent covers substantial documentation work, a contract absent from the builtin roster.
- `.mcp.json` keeps DaisyUI documentation in lazy proxy mode. Search or describe the MCP surface before connecting.

## Upgrade procedure

1. Read the package changelog, source, license, install scripts, and compatibility notes.
2. Install the candidate version in a disposable checkout.
3. Verify loaded tools/resources and check for new bundled prompts, skills, or commands.
4. Run planning, subagent, MCP, file-tool, formatting, and diagnostics smoke checks.
5. Update the exact pin and this table in the same change.

Do not run `pi update --extensions` expecting pins to move; pinned npm packages are intentionally skipped.

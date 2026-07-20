# Documentation standards

Canonical conventions for Markdown and in-code documentation in workspace.

## Voice

- Use timeless present tense. Change history belongs in commits and pull requests.
- Avoid marketing language and filler.
- Document what code does, not what it should do.

## Structure

| Location | Purpose |
| --- | --- |
| [`AGENTS.md`](../../AGENTS.md) | Cross-workspace agent policy and completion checks |
| `projects/<name>/AGENTS.md` | Project stack, boundaries, commands, and tests |
| [`docs/ARCHITECTURE.md`](../ARCHITECTURE.md) | Current repository layout, tooling, and service topology |
| [`docs/pi-harness/`](../pi-harness/) | Pi setup, provenance, skills, agents, and workflows |
| [`docs/references/`](../references/) | Lookup tables and operational reference |
| [`docs/design-docs/`](../design-docs/) | Durable architecture decisions and rationale |
| [`docs/prompts/`](../prompts/) | Approved Plannotator plans, authored directly at their canonical path |

## Update in the same change

Update relevant documentation when behavior, public APIs, configuration, architecture, or developer workflow changes. Record new service connections in `docs/ARCHITECTURE.md`.

## Markdown

- Tag every code block with its language.
- Use paths relative to the current document and verify each link target.
- Do not use emoji except the established approved-plan status glyphs or when explicitly requested.
- [`.markdownlint-cli2.jsonc`](../../.markdownlint-cli2.jsonc) disables line-length and table-column alignment checks; all other configured Markdown rules still apply.

## In-code documentation

- Default to no comment. Add one only for a non-obvious constraint, invariant, or workaround.
- Do not explain behavior already clear from names and structure.
- Do not reference the current task or pull request in source comments.

## Audience

Write for humans and coding agents. State prerequisites and commands exactly, name the consumer of each configuration setting, use tables for structured reference, and link to canonical detail instead of duplicating it.

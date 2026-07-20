---
name: codebase-analysis
description: Systematic, evidence-backed codebase exploration and research. Use when understanding unfamiliar code, architecture evaluation, security or performance review, or any research-heavy investigation.
---

# Codebase Analysis

## When to use this skill

Use when you need **evidence-backed** understanding of the codebase:

- Unfamiliar code, tracing behavior, or architecture evaluation
- Security review, performance analysis, or quality-focused investigation
- Research-heavy work before planning or refactoring

**Skip** when you already have the evidence (known scope, user-provided context, simple bug fix).

## Code quality convention documents

Prompts for detecting code smells, organized by cognitive mode (`01`–`08`). Use the **applicability matrix** to see which groups apply to which review phase; use the **convention documents** table to pick files by topic.

### Convention documents

| File | Cognitive mode | Categories |
| ---------------------------------- | ------------------------------------ | ---------- |
| `01-naming-and-types.md` | Do names and types express intent? | 5 |
| `02-structure-and-composition.md` | Is this well-structured? | 5 |
| `03-patterns-and-idioms.md` | Is this idiomatic? | 5 |
| `04-repetition-and-consistency.md` | Is this DRY and consistent? | 5 |
| `05-documentation-and-tests.md` | Is this documented and tested? | 4 |
| `06-module-and-dependencies.md` | Are boundaries clean? | 2 |
| `07-cross-file-consistency.md` | Is this consistent across files? | 4 |
| `08-codebase-patterns.md` | What patterns are emerging? | 3 |

### Applicability matrix

| Group | Design Review | Diff Review | Codebase Review | Refactor Design | Refactor Code |
| --------------------------- | :-----------: | :---------: | :-------------: | :-------------: | :-----------: |
| 01 Naming & Types | Yes | Yes | Yes | Yes | Yes |
| 02 Structure & Composition | Yes | Yes | Yes | Yes | Yes |
| 03 Patterns & Idioms | No | Yes | Yes | No | Yes |
| 04 Repetition & Consistency | No | Yes | Yes | No | Yes |
| 05 Documentation & Tests | No | Yes | Yes | No | Yes |
| 06 Module & Dependencies | Yes | No | Yes | Yes | Yes |
| 07 Cross-file Consistency | Yes | No | Yes | Yes | Yes |
| 08 Codebase Patterns | No | No | Yes | No | Yes |

### Phase definitions

- **Design Review** — Evaluating code intent before diffs exist
- **Diff Review** — Evaluating proposed code changes in plan
- **Codebase Review** — Evaluating code after implementation
- **Refactor Design** — Analyzing architecture/intent quality in existing code
- **Refactor Code** — Analyzing implementation quality in existing code

### See also

Repo workflow (Pi harness, environment variables, Nx tasks): [docs/references/README.md](../../../docs/references/README.md).

## Using reference documents

- **Focus selection (phase 2)** — Map the user's goal and P1/P2 areas to one or more groups using the **convention documents** table and **applicability matrix** above (e.g. structure → `02`; boundaries → `06`; cross-file drift → `07`).
- **Deep analysis (phase 4)** — Read [META.md](./references/META.md) when you need format, `<design-mode>` / `<code-mode>`, or how categories are structured. Read the selected `01`–`08` files and apply their **Detect** questions and `<principle>` blocks. For implementation-focused work, follow **`<code-mode>`**; for intent-only or design evaluation, follow **`<design-mode>`**.
- **Interpretation** — Categories illustrate principles, not exhaustive checklists; grep-hints are starting points, not definitive. Flag violations of the principle, including unlisted patterns.
- **Synthesis (phase 6)** — Align severity with reference `<threshold>` / severity examples where applicable; keep `filepath:line` citations.

## Systematic Investigation Phases

1. **Exploration** — Survey structure, tech stack, and patterns (delegate to sub-agents if you hold the Task/Agent tool and the repo is large — see Sub-Agent Usage below). Process: what's here, how it's organized, key entry points.
2. **Focus selection** — Classify areas (e.g. architecture, performance, security, quality) and assign priority (P1/P2/P3) based on the user's goal; tie P1/P2 to convention groups using the tables above.
3. **Investigation planning** — Commit to specific files and questions; list what you will answer and how.
4. **Deep analysis** — Investigate progressively; document with `filepath:line` citations and short quoted code. For parallel or heavy research, delegate to sub-agents when the Task/Agent tool is available; otherwise investigate inline. Load selected `01`–`08` reference files as lenses.
5. **Verification** — Check that every planned question or commitment is addressed.
6. **Synthesis** — Consolidate by severity (e.g. CRITICAL/HIGH/MEDIUM/LOW); provide prioritized findings and recommendations with `filepath:line` references.

## Sub-Agent (Task Tool) Usage

**Applies only if you hold the subagent delegation tool.** Subagents without that tool execute every phase inline, doing their own reads, searches, and traces. The guidance below is for the orchestrator (or any caller that holds the tool).

Delegate research with the Task tool when the work requires many reads, searches, or tool calls that would pollute the parent context. Good for: locating definitions/usages, tracing data flow, identifying patterns, reviewing docs or specs.

**When not to use sub-agents**: Single file read or search; role-based agents ("frontend agent", "backend agent"); micro-optimizing tools per sub-agent.

**Prompt structure**: State the question clearly; constrain scope (dirs, files, modules); request a condensed answer with `filepath:line` citations.

**Response format**: Sub-agents return a condensed answer (not a full transcript), `filepath:line` for every claim, and patterns or conventions observed. This keeps the parent context clean and allows follow-up.

## Cost Awareness

Use sub-agents for discrete, well-scoped tasks that a smaller or faster model can handle; keep orchestration and planning in the parent thread.

## References

- [META.md](./references/META.md) — Document format, `<design-mode>` / `<code-mode>`, category structure, interpretation and extension notes
- [01-naming-and-types.md](./references/01-naming-and-types.md) — Names and types express intent
- [02-structure-and-composition.md](./references/02-structure-and-composition.md) — Structure and composition
- [03-patterns-and-idioms.md](./references/03-patterns-and-idioms.md) — Idiomatic patterns
- [04-repetition-and-consistency.md](./references/04-repetition-and-consistency.md) — DRY and consistency
- [05-documentation-and-tests.md](./references/05-documentation-and-tests.md) — Documentation and tests
- [06-module-and-dependencies.md](./references/06-module-and-dependencies.md) — Module boundaries and dependencies
- [07-cross-file-consistency.md](./references/07-cross-file-consistency.md) — Cross-file consistency
- [08-codebase-patterns.md](./references/08-codebase-patterns.md) — Emerging codebase patterns

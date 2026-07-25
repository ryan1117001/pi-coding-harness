---
name: record-plan-draft
description: Validate and record a canonical Markdown plan draft and its matching reviewed chain before user approval. Never register approval or start implementation.
---

# Record a plan draft

Use this procedure after the parent has prepared a canonical draft and matching plan-specific chain, but before user approval. It records one public `📝 draft` row in [`docs/prompts/README.md`](../../../docs/prompts/README.md). It does not execute a chain or begin implementation.

## Required shape

```text
docs/prompts/
  README.md
  YYYY_MM_DD_HHMM-brief-description/
    README.md
.pi/chains/saved-plans/
  YYYY_MM_DD_HHMM-brief-description.chain.json
```

- The canonical plan path uses `docs/prompts/YYYY_MM_DD_HHMM-slug/README.md`.
- The plan has frontmatter `status: draft` and contains `Goal`, `Workflow`, and `Steps` sections.
- Its `Workflow` section links to the exact matching chain under `.pi/chains/saved-plans/`.
- The chain name, description, and canonical-plan link use the same timestamp and slug.
- A draft chain is review material only. Do not run it until the linked plan is explicitly user-approved and registered.

## Procedure

1. Read the canonical plan, its matching chain, and the plan index.
2. Reject non-canonical paths, a status other than `draft`, a missing required section, a missing or mismatched chain link, or a missing/mismatched chain file.
3. Find rows in the plan index for the exact canonical plan path.
4. If no row exists, add one `📝 draft` row with a concise outcome description. If exactly one `📝 draft` row exists, leave it as the idempotent record. If a row has another status or multiple rows exist, stop and ask the parent to resolve the conflict.
5. Recheck that the index link resolves and that no chain was run.

## Prohibited

- Inferring user approval or changing `status: draft` to `status: approved`.
- Registering the plan as `⬜ not started`.
- Starting `/run-chain`, starting implementation, or updating implementation checkboxes.
- Copying, moving, or rewriting the canonical plan or its planning artifacts.

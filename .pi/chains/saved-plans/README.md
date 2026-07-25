# Approved, registered plan chains

This directory contains plan-specific `pi-subagents` execution chains. A chain uses the same timestamp and slug as its canonical plan:

```text
docs/prompts/YYYY_MM_DD_HHMM-slug/README.md
.pi/chains/saved-plans/YYYY_MM_DD_HHMM-slug.chain.json
```

Run a chain in this directory only when its linked plan has explicit user approval and `save-approved-plan` has registered it in the [plan index](../../../docs/prompts/README.md). The parent verifies those conditions before `/run-chain`; chain discovery does not enforce approval or registration.

Use [`../workflows/`](../workflows/README.md) for reusable generic chains. Do not place a generic workflow in this directory.

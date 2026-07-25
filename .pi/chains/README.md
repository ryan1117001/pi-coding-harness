# Chain namespaces

`.pi/chains/` contains saved `pi-subagents` chains.

- [`saved-plans/`](saved-plans/README.md) contains plan-specific execution chains. Run one only when its linked canonical plan has explicit user approval and is registered in `docs/prompts/README.md`. The parent verifies these conditions before `/run-chain`; discovery does not enforce them.
- [`workflows/`](workflows/README.md) is reserved for reusable generic chains.

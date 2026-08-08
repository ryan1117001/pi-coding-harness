# docs/design-docs/

Durable design records contain architectural decisions and the rationale behind cross-service connections. Capture the decision and alternatives here; [`../ARCHITECTURE.md`](../ARCHITECTURE.md) records the resulting current topology.

## When to add one

- Before a project begins communicating with another service over HTTP, a database connection, or an external API.
- When a change reshapes architecture and future readers need the reasoning.

After approval, update [`../ARCHITECTURE.md`](../ARCHITECTURE.md). Follow [`../standards/documentation.md`](../standards/documentation.md).

## Conventions

- One decision per `NNNN-short-slug.md`, using an incrementing zero-padded number.
- State context, decision, consequences, and alternatives considered.
- Use timeless present tense.

## Contents

- [0001: Compose-backed Dev Container workspace](0001-devcontainer-workspace.md) — records the development workspace topology and host-Docker trust boundary.
- [0002: Optional Docker Sandbox Pi runtime](0002-docker-sandbox-pi-runtime.md) — records the opt-in Sandbox boundary, source clone, trusted Pi input, and evidence limits.

---
description: Verify frontend projects do not call storage backends or external APIs directly
---

# Architecture boundary check

Review browser/frontend code for service-boundary violations. Read `AGENTS.md`, the relevant project `AGENTS.md`, and `docs/ARCHITECTURE.md` first.

Run targeted searches under frontend TypeScript sources for:

1. Storage clients or connection material: `DATABASE_URL`, `DB_URL`, `STORAGE_URL`, `connectionString`, `createClient(`, Supabase, PlanetScale, Neon, Redis, MongoDB, or DuckDB.
2. LLM or other third-party endpoints and embedded authorization: Anthropic/OpenAI/Generative AI hosts, `/v1/messages`, `/v1/chat`, or bearer authorization.
3. Absolute `http://` or `https://` fetches and absolute HTTP-client base URLs.

A browser call to an absolute external host, direct storage backend, embedded external credential, or third-party API is a violation unless the approved architecture explicitly documents it. Browser code should use its own backend through a relative/proxied client. Test-runner and local preview configuration, such as Playwright's `baseURL`, is not shipped browser code and is not a violation.

For each violation, report `filepath:line`, quote the offending line, and name the backend boundary it should use. If no violations exist, state: `Architecture clean — no forbidden connections detected.`

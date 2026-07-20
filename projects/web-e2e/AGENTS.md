# Web end-to-end project instructions

Playwright end-to-end tests for the `web` app. Specs live in `src/` and run against `web:preview` at `BASE_URL` (default `http://localhost:4200`).

## Conventions

- Follow RED, GREEN, REFACTOR for user-visible behavior changes.
- Test user-observable flows across the application boundary; keep component details in `web` unit or story tests.
- Prefer role, label, text, and test-id locators over CSS selectors. Use `page.getByRole(...)` when possible.
- Use Playwright's web-first assertions and locator auto-waiting; do not add arbitrary sleeps.
- Keep tests independent and deterministic. Create only the state a test needs and do not depend on execution order.
- Preserve the Chromium, Firefox, and WebKit projects unless an approved requirement changes browser coverage.
- Traces remain enabled on first retry; use them before adding diagnostic screenshots or logs.

## Commands

```bash
pnpm exec playwright install
pnpm exec nx e2e web-e2e
BASE_URL=https://example.test pnpm exec nx e2e web-e2e
```

# web-e2e

Playwright end-to-end tests for the [`web`](../web/) app. Specs live in `src/`.
`web-e2e` has an implicit dependency on `web`, so Nx rebuilds `web` when it is affected.

## Quick start

```bash
pnpm exec playwright install      # browsers: chromium, firefox, webkit
pnpm exec nx e2e web-e2e          # runs the suite against a preview build of web
```

[`playwright.config.ts`](playwright.config.ts) starts `web` via `nx run web:preview`
on http://localhost:4200 (override with `BASE_URL`) and runs specs across chromium,
firefox, and webkit. Traces are captured on first retry.

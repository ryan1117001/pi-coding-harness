# web-e2e

Playwright end-to-end tests for the [`web`](../web/) app. Specs live in `src/`.
`web-e2e` has an implicit dependency on `web`, so Nx rebuilds `web` when it is affected.

## Quick start

Run the commands below from the repository root. Install all Playwright browsers before running the suite:

```bash
pnpm exec playwright install      # browsers: chromium, firefox, webkit
pnpm exec nx e2e web-e2e          # runs the suite against a preview build of web
```

[`playwright.config.ts`](playwright.config.ts) starts `web` via `nx run web:preview`
on `http://localhost:4200` and runs specs across Chromium, Firefox, and WebKit. `BASE_URL`
changes Playwright's `use.baseURL`; `webServer.url` remains the local preview URL.
Traces are captured on first retry.

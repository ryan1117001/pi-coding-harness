# web

React 19 single-page app built with Vite 8. File-based routing via TanStack
Router, server state via TanStack Query, styling with Tailwind CSS v4 + daisyUI v5,
and testing with Vitest 4 + Storybook. Components follow atomic design.

See [`AGENTS.md`](AGENTS.md) for component boundaries, styling, tests, and generated-file constraints.
Translations use Paraglide JS with English message files under [`messages/`](messages/). The Vite plugin generates `src/paraglide/` during development and builds.

## Quick start

Run the commands below from the repository root. Storybook browser tests require Chromium; unit tests use jsdom:

```bash
pnpm exec playwright install chromium
pnpm exec nx serve web            # dev server at http://localhost:4200
```

## Commands

```bash
pnpm exec nx build web            # production build (regenerates src/routeTree.gen.ts)
pnpm exec nx test web             # Vitest: unit specs (jsdom) + stories in Chromium; coverage fails under 85%
pnpm exec nx typecheck web        # tsc --build
pnpm exec nx lint web             # Biome check
pnpm exec nx lint:fix web         # apply safe Biome lint fixes
pnpm exec nx format web           # Biome format check
pnpm exec nx format:fix web       # apply Biome formatting
pnpm exec nx storybook web        # Storybook dev
```

Styling is configured CSS-first in `src/styles.css` — there is no `tailwind.config.js`.
The active theme is `workspace-light`, a custom daisyUI theme (light-only).
The web server listens on port 4200 and has no configured browser-to-API connection. Browser calls to backend or external services follow the boundary in [`AGENTS.md`](AGENTS.md) and [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md). End-to-end tests live in [`../web-e2e/`](../web-e2e/).

Paraglide message files use the Inlang message format. Run `pnpm exec paraglide-js compile --project projects/web/project.inlang --outdir projects/web/src/paraglide --emit-ts-declarations` when editor types need to be regenerated outside Vite.

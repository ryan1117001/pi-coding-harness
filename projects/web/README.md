# web

React 19 single-page app built with Vite 8. File-based routing via TanStack
Router, server state via TanStack Query, styling with Tailwind CSS v4 + daisyUI v5,
and testing with Vitest 4 + Storybook. Components follow atomic design.

See [`AGENTS.md`](AGENTS.md) for component boundaries, styling, tests, generated files, and commands.

## Quick start

```bash
pnpm exec nx serve web            # dev server at http://localhost:4200
```

## Commands

```bash
pnpm exec nx build web            # production build (regenerates src/routeTree.gen.ts)
pnpm exec nx test web             # Vitest: unit specs (jsdom) + stories in Chromium; coverage fails under 85%
pnpm exec nx typecheck web        # tsc --build
pnpm exec nx lint web             # Biome check
pnpm exec nx storybook web        # Storybook dev
```

Styling is configured CSS-first in `src/styles.css` — there is no `tailwind.config.js`.
The active theme is `workspace-light`, a custom daisyUI theme (light-only).

Story and browser tests need Playwright's Chromium: `pnpm exec playwright install chromium`.
End-to-end tests live in [`../web-e2e/`](../web-e2e/).

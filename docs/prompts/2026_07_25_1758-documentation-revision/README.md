---
status: approved
---

# Revise repository documentation

## Goal

Make active repository-authored documentation accurate, concise, navigable, and actionable for humans and coding agents without changing behavior or altering immutable planning records.

## Scope

Revise active Markdown at the repository root, under `docs/`, under `projects/`, and under `.pi/`, plus local skills not listed in `skills-lock.json`. Also update the explicitly requested user-scoped subagent profiles at `/Users/huaryan/.pi/agent/profiles/pi-subagents/{default,high-effort}.json`. Recheck every in-scope document; edit only when a concrete factual, clarity, consistency, or navigation improvement is warranted.

Exclude third-party or generated material: all `skills-lock.json`-tracked skills, `.pi/npm/`, `node_modules/`, virtual environments, caches, runtime artifacts, generated Paraglide and route-tree files, and `projects/web/project.inlang/README.md`. Preserve every dated `docs/prompts/YYYY_MM_DD_HHMM-*/` archive and its matching saved chain; after approval, only completed canonical-plan checkboxes may change.

Documentation and the one approved user-profile configuration change use the documented TDD/configuration exceptions. Any other source, configuration, dependency, or behavior change stops for separate approval.

## Factual decisions

1. `.pi/settings.json` defines the configured Pi package set, not exact version pins or a lock-backed reproducible install. Documentation must not claim otherwise.
2. `docs/coding-agent-harness/extensions.md` lists all eight configured packages, including `npm:@narumitw/pi-retry`, without unverified versions.
3. `skills-lock.json` identifies 11 vendored skills. Only the five local skills—`codebase-analysis`, `multi-stage-dockerfile`, `record-plan-draft`, `save-approved-plan`, and `webapp-testing`—may be revised.
4. `compose.yml`, source, Dockerfiles, and project configuration are the behavior authority. Documentation names consumers and labels tables as documented defaults.
5. Preserve current topology: `web` runs on `:4200` and has no configured browser-to-API connection; `api` runs on `:8000` and connects to PostgreSQL; Compose changes the API database host from `localhost` to `postgres`.
6. Document current operational constraints precisely: `origin/main` is required for affected checks; E2E `BASE_URL` changes `use.baseURL` while `webServer.url` remains local; PostgreSQL initialization settings apply only on first volume initialization; committed PostgreSQL defaults are local-development-only.
7. **User-profile model policy:** Keep `defaultModel` as `openai-codex/gpt-5.6-terra`; retain the existing Scout, Researcher, Planner, Context-builder, Worker, Reviewer, and Delegate assignments; set `technical-writer` to Terra + medium and `oracle` to Sol + medium; keep the watchdog at Sol + high; and order each fallback list with its explicit GitHub Copilot Claude model before `cursor/auto`.
8. **High-effort user profile:** Keep `defaultModel` and the watchdog at Sol + high. Use Terra + medium for Scout; Terra + high for Technical Writer; Sol + medium for Researcher, Context-builder, Worker, and Delegate; and Sol + high for Planner, Reviewer, and Oracle. Use explicit GitHub Copilot Claude fallbacks before `cursor/auto`: Opus for Planner, Worker, Reviewer, and Oracle; Sonnet for the remaining roles. The same-provider watchdog is intentional for consistency, not independent-model diversity.

## Documents to review

| Batch | Documents | Outcome |
| --- | --- | --- |
| Entry points and policy | `README.md`, `CONTRIBUTING.md`, `AGENTS.md` | Accurate setup, prerequisites, package wording, plan lifecycle, and command preconditions. |
| Workspace documentation | `docs/README.md`, `docs/ARCHITECTURE.md`, `docs/standards/documentation.md`, all `docs/coding-agent-harness/*.md`, `docs/design-docs/README.md`, `docs/prompts/README.md`, and `docs/references/*.md` | Canonical navigation, factual configuration/provenance claims, concise lifecycle guidance, and truthful environment authority. |
| Project documentation | `README.md` and `AGENTS.md` in `projects/web`, `projects/web-e2e`, `projects/api`, and `projects/postgres` | Self-contained onboarding, repo-root commands, boundaries, safety constraints, diagnostics, and one authoritative detailed command source per project. |
| Pi documentation | `.pi/agents/*.md`, `.pi/chains/**/*.md`, `.pi/prompts/*.md` | Working relative links, concise role/namespace contracts, and lifecycle guidance that does not duplicate the canonical workflow. |
| Local skills | `.agents/skills/codebase-analysis/{SKILL.md,references/*.md}`, plus local `multi-stage-dockerfile`, `record-plan-draft`, `save-approved-plan`, and `webapp-testing` `SKILL.md` files | Current Pi, Playwright, and MCP assumptions; clear parent/child boundaries; no edits to vendored skills. |
| User profiles | `/Users/huaryan/.pi/agent/profiles/pi-subagents/{default,high-effort}.json` | Requested model/thinking defaults and fallback ordering; JSON validity, profile checks, and live effective mapping verification. |

## Workflow

Use the matching plan-specific chain: [`.pi/chains/saved-plans/2026_07_25_1758-documentation-revision.chain.json`](../../../.pi/chains/saved-plans/2026_07_25_1758-documentation-revision.chain.json). It is review material only until this plan receives explicit approval and is registered through `save-approved-plan`.

## Steps

- [x] Reconfirm each revised fact against `.pi/settings.json`, `skills-lock.json`, `compose.yml`, project configuration, source, Dockerfiles, and the current user profile. Qualify or omit anything not established by a repository source.
- [x] Update the user profiles only as requested. In `default.json`, set technical-writer to Terra + medium, oracle to Sol + medium, explicit Claude fallbacks before `cursor/auto`, and watchdog Sol + high; preserve other role defaults. In `high-effort.json`, apply the approved Sol/Terra model and thinking matrix, Claude-first fallbacks, and intentional Sol + high watchdog. Validate both JSON files, check and load each profile, verify live mappings/watchdog state, then restore `default` unless the user chooses to leave high-effort active.
- [x] Revise root and `docs/` documentation: remove unsupported package-pin/reproducibility claims; distinguish local and vendored skills; include `pi-retry`; make `workflows.md` and `docs/prompts/README.md` the detailed lifecycle sources; clarify environment-document authority; remove the unrelated design-doc/Nx reference.
- [x] Revise the four project README/AGENTS pairs: state prerequisites and working-directory expectations, preserve the web/API boundary, make E2E URL semantics explicit, distinguish host and Compose API database hosts, and foreground PostgreSQL first-init, extension, and local-security constraints.
- [x] Revise active `.pi` documentation and local skills only where needed: replace bare links, remove duplicated lifecycle explanation, retain approval/registration gates, and align local guidance with the repository’s Pi, Playwright, and DaisyUI MCP setup.
- [x] Keep one writer for all documentation edits. Use direct present-tense language, language-tagged code blocks, repository-relative links, named configuration consumers, compact structured tables, and canonical links instead of duplicated detail.
- [x] Obtain read-only factual/scope and documentation/usability reviews. The sole writer applies only accepted findings; record deferred findings as residual risk.
- [x] Validate the final documentation diff, user-profile JSON, local links, copied commands, Markdown lint, live subagent mapping/watchdog status, and required workspace checks. Update these checkboxes and the plan index only from actual evidence.

## Validation

```bash
# Formatting and Markdown quality for changed documentation
git diff --check
pnpm exec markdownlint-cli2 $(git diff --name-only --diff-filter=ACMR -- '*.md')

# Recheck facts cited by the revised documentation
node --input-type=module -e "const fs=require('node:fs'); const s=JSON.parse(fs.readFileSync('.pi/settings.json','utf8')); if (s.packages.length !== 8 || !s.packages.includes('npm:@narumitw/pi-retry')) process.exit(1); console.log(s.packages.join('\\n'))"
grep -nE 'thresholds|statements: 85|branches: 85|functions: 85|lines: 85' projects/web/vite.config.mts
grep -nE 'baseURL|webServer|url:' projects/web-e2e/playwright.config.ts
grep -nE 'DATABASE_URL|postgres:5432|service_healthy' compose.yml projects/api/project.json
grep -nE 'AGE_VERSION|postgres:18-bookworm|CREATE EXTENSION|first init|down -v' projects/postgres/Dockerfile projects/postgres/README.md projects/postgres/AGENTS.md
jq empty /Users/huaryan/.pi/agent/profiles/pi-subagents/default.json
jq empty /Users/huaryan/.pi/agent/profiles/pi-subagents/high-effort.json
# Check and load each profile in Pi, verify its effective configuration, then restore the default profile.
/subagents-check-profile default
/subagents-load-profile default
/subagents-models
/subagents-watchdog status
/subagents-check-profile high-effort
/subagents-load-profile high-effort
/subagents-models
/subagents-watchdog status
/subagents-load-profile default

# Required workspace completion check; report an unavailable origin/main ref rather than changing the base.
pnpm exec nx affected -t lint test --base=origin/main --parallel=3
```

Also run a repository-relative link scan over changed Markdown and manually verify anchors. Run the builtin reviewer on the final diff. Lens diagnostics and behavior tests do not apply to Markdown-only edits; if scope expands to source or configuration, stop and obtain approval.

## Risks

- Effective Pi package versions are outside the approved scope, so remove unsupported version claims rather than infer them.
- Documentation must not become configuration, Docker, Playwright, or product-behavior work.
- The user-profile changes affect future subagent routing outside this repository. Validate both profiles after reload, restore `default` after high-effort validation unless the user elects otherwise, and do not claim fallback quality validation; fallbacks apply only when model/provider selection fails.
- PostgreSQL examples must use a disposable volume/database when validating first-init or extension guidance.
- Markdown lint does not validate every anchor or external URL; report unverified external links and manually validate changed local anchors.

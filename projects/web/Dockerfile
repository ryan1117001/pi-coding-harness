# syntax=docker/dockerfile:1
#
# Multi-stage build for the `web` Vite/React app (Nx + pnpm workspace).
# Build context is the repo root so the pnpm workspace resolves correctly:
#   docker build -f projects/web/Dockerfile --target runtime -t workspace-web .
#
# Stages:
#   base    — pinned Node + pnpm (corepack)
#   deps    — install the workspace dependency graph (cached on manifests)
#   dev     — Vite dev server with HMR; compose `develop` targets this
#   build   — emit the static production bundle to projects/web/dist
#   runtime — serve the bundle via non-root nginx

###############################################################################
# base — pinned toolchain shared by every downstream stage.
###############################################################################
FROM node:24-alpine AS base
ENV PNPM_HOME="/pnpm" \
    PATH="/pnpm:$PATH"
# Match the workspace's packageManager pin for reproducible installs.
RUN corepack enable && corepack prepare pnpm@11.9.0 --activate
WORKDIR /workspace

###############################################################################
# deps — install dependencies. This layer is cached until a manifest or the
# lockfile changes, so source edits don't trigger a reinstall.
###############################################################################
FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY projects/web/package.json ./projects/web/
COPY projects/web-e2e/package.json ./projects/web-e2e/
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store \
    pnpm install --frozen-lockfile

###############################################################################
# dev — Vite dev server with hot reload. Bind to 0.0.0.0 so the port is
# reachable from the host. `docker compose watch` syncs source into this stage.
###############################################################################
FROM deps AS dev
COPY . .
EXPOSE 4200
CMD ["pnpm", "exec", "nx", "run", "web:dev", "--host", "0.0.0.0", "--port", "4200"]

###############################################################################
# build — produce the optimized static bundle in projects/web/dist.
###############################################################################
FROM deps AS build
COPY . .
RUN pnpm exec nx run web:build

###############################################################################
# runtime — minimal, non-root static server for the built bundle.
# nginx-unprivileged runs as uid 101 and listens on 8080.
###############################################################################
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime
COPY projects/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /workspace/projects/web/dist /usr/share/nginx/html
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/ >/dev/null 2>&1 || exit 1

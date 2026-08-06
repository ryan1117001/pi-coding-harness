# Uses the Docker Engine's bundled frontend; no mutable external frontend is selected.

# Multi-architecture manifest digests for uv 0.11.14, Node 24.18.0
# (bookworm), and the Ubuntu 24.04 Dev Container base.

FROM ghcr.io/astral-sh/uv@sha256:1025398289b62de8269e70c45b91ffa37c373f38118d7da036fb8bb8efc85d97 AS uv

FROM node@sha256:5711a0d445a1af54af9589066c646df387d1831a608226f4cd694fc59e745059 AS node

FROM mcr.microsoft.com/devcontainers/base@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae

COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=node /usr/local/ /usr/local/

RUN corepack enable pnpm && corepack prepare pnpm@11.15.1 --activate

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0 \
    UV_CACHE_DIR=/home/vscode/.cache/uv \
    PNPM_HOME=/home/vscode/.local/share/pnpm \
    PATH=/home/vscode/.local/share/pnpm/bin:${PATH}

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        jq \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

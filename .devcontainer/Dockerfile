# Uses the Docker Engine's bundled frontend; no mutable external frontend is selected.

# Multi-architecture manifest digests for uv 0.12.2, Node 24.19.0
# (bookworm), and the Ubuntu 24.04 Dev Container base.

FROM ghcr.io/astral-sh/uv@sha256:069a51314a7bb6031777a9273205fe1b0b19e914ef418207d1338b268df641dd AS uv

FROM node:24.19.0-bookworm@sha256:934240a162082fd8b8a2f90cd5114446443f1eba1c5378f6687167ca405e6584 AS node

FROM mcr.microsoft.com/devcontainers/base@sha256:d94c97dd9cacf183d0a6fd12a8e87b526e9e928307674ae9c94139139c0c6eae

COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=node /usr/local/ /usr/local/

RUN corepack enable pnpm && corepack prepare pnpm@11.20.0 --activate

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

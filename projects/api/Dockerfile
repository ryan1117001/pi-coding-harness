# syntax=docker/dockerfile:1
#
# Multi-stage build for the `api` FastAPI service (Python 3.14, uv).
# Build context is this project directory (it is self-contained — pyproject.toml,
# uv.lock, and source all live here):
#   docker build -f projects/api/Dockerfile --target runtime -t workspace-api projects/api
#
# Stages:
#   base    — Python 3.14 slim + the uv binary
#   deps    — resolve the locked dependency graph (cached on uv.lock/pyproject.toml)
#   build   — install the project into a self-contained .venv
#   runtime — minimal, non-root image running uvicorn

###############################################################################
# base — pinned toolchain shared by the build stages.
###############################################################################
FROM python:3.14.4-slim-bookworm@sha256:fc74d22ffd0d5ac395a4b7bdda75a4539758862c49ebf3005647084631e63789 AS base
# Pin uv to the workspace's version for reproducible installs.
COPY --from=ghcr.io/astral-sh/uv@sha256:069a51314a7bb6031777a9273205fe1b0b19e914ef418207d1338b268df641dd /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0
WORKDIR /app

###############################################################################
# deps — install dependencies only. Cached until uv.lock or pyproject.toml
# changes, so source edits don't trigger a reinstall.
###############################################################################
FROM base AS deps
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project --no-dev

###############################################################################
# build — add the source and install the project into /app/.venv.
###############################################################################
FROM deps AS build
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev

###############################################################################
# runtime — minimal, non-root image. Only the venv and source are carried over.
###############################################################################
FROM python:3.14.4-slim-bookworm@sha256:fc74d22ffd0d5ac395a4b7bdda75a4539758862c49ebf3005647084631e63789 AS runtime
RUN groupadd --system app && useradd --system --gid app --home-dir /app app
WORKDIR /app
COPY --from=build --chown=app:app /app /app
ENV PATH="/app/.venv/bin:$PATH"
USER app
EXPOSE 8000
# Liveness probe — /api/v1/health does not touch the database.
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/api/v1/health').status == 200 else 1)"
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]

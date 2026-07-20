# syntax=docker/dockerfile:1
# Official PostgreSQL 18 with two extensions:
#   - pgvector    – vector similarity search (PGDG apt package)
#   - Apache AGE  – graph database (compiled from source)
#
# AGE is compiled in a builder stage and its artifacts copied into the runtime image
# to keep it small.
#
# Build args:
#   AGE_VERSION       – Apache AGE release tag (PG-major-scoped, e.g. PG18/vX.Y.Z-rcN)

FROM postgres:18-bookworm AS builder

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        ca-certificates \
        postgresql-server-dev-18 \
        libreadline-dev \
        zlib1g-dev \
        flex \
        bison \
        libxml2-dev \
        libxslt-dev \
        libssl-dev \
        libxml2-utils \
        xsltproc \
        pkg-config \
        libglib2.0-dev

# --- Apache AGE ---
ARG AGE_VERSION=PG18/v1.7.0-rc0
RUN git clone --depth 1 --branch ${AGE_VERSION} https://github.com/apache/age.git /tmp/age && \
    cd /tmp/age && \
    make && \
    make install

# --- runtime stage ---
FROM postgres:18-bookworm

# pgvector from PGDG (the official image already configures the apt.postgresql.org repo).
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-18-pgvector

COPY --from=builder /usr/lib/postgresql/18/lib/age.so /usr/lib/postgresql/18/lib/
COPY --from=builder /usr/share/postgresql/18/extension/age* /usr/share/postgresql/18/extension/

# Create the databases listed in POSTGRES_EXTRA_DATABASES on first initdb.
COPY --chmod=0755 init-databases.sh /docker-entrypoint-initdb.d/init-databases.sh

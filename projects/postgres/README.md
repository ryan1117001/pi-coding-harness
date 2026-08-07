# postgres

See [`AGENTS.md`](AGENTS.md) for the image contract, first-init rules, and security constraints.

Custom PostgreSQL 18 image for local infrastructure. The image includes pgvector and Apache AGE.

Official [`postgres:18-bookworm`](https://hub.docker.com/_/postgres) with two extensions, configured in [`Dockerfile`](Dockerfile):

- [pgvector](https://github.com/pgvector/pgvector) - vector similarity search, installed from the PGDG apt package.
- [Apache AGE](https://age.apache.org/) - graph database, compiled from a pinned PG18 release tag.
  `AGE_VERSION` defaults to `PG18/v1.8.0-rc0`, the newest published PG18 tag. Apache AGE has no stable PG18 tag yet, so this explicit release candidate remains the compatibility constraint; override the build argument only with another verified PG18 tag.

Root [`compose.yml`](../../compose.yml) **builds** this image and starts the service; run `docker compose` from the repo root.

The image only makes the **`age`** extension _available_ - [`Dockerfile`](Dockerfile) compiles it from source and copies `age.so` plus the extension files into the runtime image. It is not auto-created in any database; [`init-databases.sh`](init-databases.sh) only creates extra databases. Enable the extension in a target database with `CREATE EXTENSION age;` (as for the other extensions - see below).

## Quick start

```bash
cp .env.example .env   # from repo root; optional — Compose reads `.env` there
docker compose build postgres
docker compose up -d
```

The committed Compose defaults are for local development only:

- user: `postgres`
- password: `password`
- database: `workspace`
- extra database: none
- port: `5432`

## Database

The default database (`workspace` unless overridden by `POSTGRES_DB`) is created by the image entrypoint during first initialization. The `init-databases.sh` script and initialization settings do not affect an existing volume; use `docker compose down -v` only when intentionally resetting disposable local data. [`init-databases.sh`](init-databases.sh) then creates the extra databases listed in `POSTGRES_EXTRA_DATABASES`, a comma- or whitespace-separated list. Each name must match `[A-Za-z_][A-Za-z0-9_]*`; invalid or injection-like values fail before `psql` runs.

Extensions (for example `vector`, `age`) are enabled per database with `CREATE EXTENSION` as needed.

## Useful commands

```bash
docker compose logs -f postgres
docker compose exec postgres psql -U postgres -d workspace
docker compose exec postgres psql -U postgres -d workspace -X   # non-interactive / init-safe (skips .psqlrc)
docker compose down -v    # reset data volume
pnpm exec nx test postgres  # safe identifier and input-contract tests
```

Build args can be overridden when testing extension upgrades:

```bash
docker build \
  --build-arg AGE_VERSION=<tag> \
  projects/postgres
```

## Password authentication

Password hashing uses **scram-sha-256** (the PostgreSQL 18 default for `password_encryption`). To make the generated `pg_hba.conf` require scram for host connections, set on the container:

```bash
POSTGRES_HOST_AUTH_METHOD=scram-sha-256
POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256 --auth-local=scram-sha-256"
```

The `pg_hba.conf` auth method is fixed at the first `initdb`; it does not change on a data directory that was initialized differently.

## Environment

See root [`.env.example`](../../.env.example) and [`docs/references/environment-variables.md`](../../docs/references/environment-variables.md):

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`
- `POSTGRES_EXTRA_DATABASES`
- `POSTGRES_HOST_AUTH_METHOD`
- `POSTGRES_INITDB_ARGS`
- `PGDATA`

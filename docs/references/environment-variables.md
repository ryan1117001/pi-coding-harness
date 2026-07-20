# Environment variables

Runtime configuration for workspace's services. Compose reads a repo-root `.env` if present; copy [`.env.example`](../../.env.example) to `.env` to override the defaults below. Each variable is also settable directly in the service environment.

Defaults come from [`compose.yml`](../../compose.yml) and the per-service code; the table values are authoritative.

## postgres

Consumed by the [`postgres`](../../projects/postgres/) image — the official `postgres:18` entrypoint plus [`init-databases.sh`](../../projects/postgres/init-databases.sh).

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `postgres` | Superuser created on first `initdb`. |
| `POSTGRES_PASSWORD` | `password` | Password for `POSTGRES_USER`. Override for any non-local use. |
| `POSTGRES_DB` | `workspace` | Default database created by the entrypoint. |
| `POSTGRES_EXTRA_DATABASES` | _(empty)_ | Comma- or whitespace-separated list of additional databases [`init-databases.sh`](../../projects/postgres/init-databases.sh) creates on first init. Empty means only `POSTGRES_DB`. |
| `POSTGRES_HOST_AUTH_METHOD` | _(unset)_ | Auth method baked into the generated `pg_hba.conf`. Set to `scram-sha-256` to require scram for host connections. |
| `POSTGRES_INITDB_ARGS` | _(unset)_ | Extra flags passed to `initdb`, e.g. `--auth-host=scram-sha-256 --auth-local=scram-sha-256`. |
| `PGDATA` | `/var/lib/postgresql/18/docker` | Data directory inside the container. The PG18 image stores data in a major-version subdirectory; the `postgres-data` volume mounts the parent `/var/lib/postgresql`. |

`POSTGRES_*` settings other than `POSTGRES_EXTRA_DATABASES` are fixed at the first `initdb` and do not change on a data directory initialized differently. See [`projects/postgres/README.md`](../../projects/postgres/README.md).

## api

Consumed by [`api/config.py`](../../projects/api/api/config.py) (pydantic-settings, read once per process; `DATABASE_URL` maps to the `database_url` setting).

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql+psycopg://postgres:password@localhost:5432/workspace` | Async SQLAlchemy DSN. The driver must be psycopg3's async one (`postgresql+psycopg://`). In Compose this is derived from the `POSTGRES_*` values and points at the `postgres` service host instead of `localhost`. |

## Build arguments

These are Docker build args, not runtime environment variables — set them at build time, not in `.env`:

- `AGE_VERSION` — Apache AGE release tag (PG-major-scoped) compiled into the [`postgres`](../../projects/postgres/Dockerfile) image. Override to bump the AGE version.

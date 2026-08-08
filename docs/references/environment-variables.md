# Environment variables

Runtime configuration for workspace services. Run these commands from the repository root. Compose reads a repo-root `.env` if present; copy [`.env.example`](../../.env.example) to `.env` to override documented local defaults. Each variable is also settable directly in the service environment.

[`compose.yml`](../../compose.yml), project source, and Dockerfiles are the behavior authority. This page records documented defaults and names each consumer; use the consumer's configuration when a runtime override is present.

## postgres

Consumed by the [`postgres`](../../projects/postgres/) image — the official `postgres:18` entrypoint plus [`init-databases.sh`](../../projects/postgres/init-databases.sh).

| Variable                    | Default                         | Description                                                                                                                                                                                             |
| --------------------------- | ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `POSTGRES_USER`             | `postgres`                      | Superuser created on first `initdb`.                                                                                                                                                                    |
| `POSTGRES_PASSWORD`         | `password`                      | Password for `POSTGRES_USER`. The committed Compose value is local-development-only; override it for any non-local use.                                                                                 |
| `POSTGRES_DB`               | `workspace`                     | Default database created by the entrypoint.                                                                                                                                                             |
| `POSTGRES_EXTRA_DATABASES`  | _(empty)_                       | Comma- or whitespace-separated list of additional databases created on first init. Names must match `[A-Za-z_][A-Za-z0-9_]*`; invalid values fail before SQL execution. Empty means only `POSTGRES_DB`. |
| `POSTGRES_HOST_AUTH_METHOD` | _(unset)_                       | Auth method baked into the generated `pg_hba.conf`. Set to `scram-sha-256` to require scram for host connections.                                                                                       |
| `POSTGRES_INITDB_ARGS`      | _(unset)_                       | Extra flags passed to `initdb`, e.g. `--auth-host=scram-sha-256 --auth-local=scram-sha-256`.                                                                                                            |
| `PGDATA`                    | `/var/lib/postgresql/18/docker` | Data directory inside the container. The PG18 image stores data in a major-version subdirectory; the `postgres-data` volume mounts the parent `/var/lib/postgresql`.                                    |

`POSTGRES_*` settings other than `POSTGRES_EXTRA_DATABASES` are fixed at the first `initdb` and do not change on a data directory initialized differently. Initialization scripts and extension setup also apply only to a newly initialized volume. See [`projects/postgres/README.md`](../../projects/postgres/README.md).

## api

Consumed by [`api/config.py`](../../projects/api/api/config.py) (pydantic-settings, read once per process; `DATABASE_URL` maps to the `database_url` setting). Root Compose and the Dev Container workspace set the value for API processes they start.

| Variable       | Default                                                           | Description                                                                                                                                                                                                                                                                                                                                    |
| -------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DATABASE_URL` | `postgresql+psycopg://postgres:password@localhost:5432/workspace` | Async SQLAlchemy DSN consumed by `api/config.py`. The driver must be psycopg3's async one (`postgresql+psycopg://`). This default is for an API outside Compose. Root Compose and [`.devcontainer/compose.yml`](../../.devcontainer/compose.yml) derive the DSN from `POSTGRES_*` and use `postgres` as the host for API processes they start. |

## Docker Sandbox Pi runtime

Consumed by [`.sandbox/launch-pi.sh`](../../.sandbox/launch-pi.sh) and [`.sandbox/smoke-test.sh`](../../.sandbox/smoke-test.sh). These are manual launcher inputs, not root Compose service variables. See [Docker Sandbox Pi runtime](docker-sandbox-pi.md) for validation and security boundaries.

| Variable | Consumer | Default or effect |
| --- | --- | --- |
| `PI_USER_SETTINGS` | Sandbox launcher | Host settings source for `--with-user-pi`; defaults to `~/.pi/agent/settings.json`. |
| `PI_USER_EXTENSIONS` | Sandbox launcher | Host extensions source for `--with-user-pi`; defaults to `~/.pi/agent/extensions`. |
| `SANDBOX_STATE_ROOT` | Sandbox launcher | Owned, non-symlink state root; defaults to `~/.local/state/pi-coding-harness/sandboxes`. |
| `SANDBOX_BOOTSTRAP_NETWORK` | Sandbox launcher | Comma-separated exact bootstrap destinations; replaces the default list. |
| `SANDBOX_EXPECTED_TEMPLATE_NETWORK` | Sandbox launcher | Comma-separated exact `host:port` rules the template may ship; replaces the default `openrouter.ai:443`. Needed only for a template whose built-in policy differs. |
| `SANDBOX_SKIP_BROWSER` | Sandbox launcher and bootstrap | `1` skips Chromium installation and smoke launch checks. |
| `SANDBOX_LIVE_SMOKE` | Sandbox smoke helper | Must equal `1` before the helper starts disposable live work. |
| `SANDBOX_SMOKE_COMPOSE` | Sandbox smoke helper | `1` enables the nested PostgreSQL Compose smoke. |

`SANDBOX_PI_SETTINGS_SOURCE` and `SANDBOX_PI_EXTENSIONS_SOURCE` are private launcher-to-bootstrap inputs, not user configuration.

## Build arguments

These are Docker build args, not runtime environment variables — set them at build time, not in `.env`:

- `AGE_VERSION` — Apache AGE release tag (PG-major-scoped) compiled into the [`postgres`](../../projects/postgres/Dockerfile) image. Override to bump the AGE version.

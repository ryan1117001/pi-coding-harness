# PostgreSQL project instructions

This infrastructure project owns the custom PostgreSQL 18 image and first-initialization scripts.

## Contract

- Keep `vector` available from the PGDG package.
- Keep Apache AGE available from its pinned source tag.
- Treat `docker-entrypoint-initdb.d/` scripts as first-init-only; changes do not affect an existing volume.
- Keep initialization scripts POSIX-shell compatible and fail fast.
- Accept extra database names only when they match `[A-Za-z_][A-Za-z0-9_]*`; keep SQL identifiers parameterized.
- Do not create extensions in every database unless the approved requirement changes that contract.
- Treat committed Compose credentials as local-development-only; never commit real passwords, connection strings, CIDR allowlists, or cloud account secrets.
- When environment variables change, update root `.env.example` and `docs/references/environment-variables.md` in the same change.

Operational commands live in [`README.md`](README.md).

Use `docker compose down -v` only when intentionally validating first-init behavior; it destroys local data.

For Dockerfile or initialization changes, run the shell contract tests, rebuild from an empty volume, and verify availability:

```sql
SELECT name, default_version
FROM pg_available_extensions
WHERE name IN ('vector', 'age');
```

Instantiate an extension with `CREATE EXTENSION` only in the database that needs it for the test.

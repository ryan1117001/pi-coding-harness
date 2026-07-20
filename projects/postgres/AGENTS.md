# PostgreSQL project instructions

This infrastructure project owns the custom PostgreSQL 18 image and first-initialization scripts.

## Contract

- Keep `vector` available from the PGDG package.
- Keep Apache AGE available from its pinned source tag.
- Treat `docker-entrypoint-initdb.d/` scripts as first-init-only; changes do not affect an existing volume.
- Keep initialization scripts POSIX-shell compatible and fail fast.
- Do not create extensions in every database unless the approved requirement changes that contract.
- Never commit real passwords, connection strings, CIDR allowlists, or cloud account secrets.
- When environment variables change, update root `.env.example` and `docs/references/environment-variables.md` in the same change.

## Commands

```bash
docker compose build postgres
docker compose up -d postgres
docker compose logs -f postgres
docker compose exec postgres psql -U postgres -d workspace
```

Use `docker compose down -v` only when intentionally validating first-init behavior; it destroys local data.

For Dockerfile or initialization changes, rebuild from an empty volume and verify availability:

```sql
SELECT name, default_version
FROM pg_available_extensions
WHERE name IN ('vector', 'age');
```

Instantiate an extension with `CREATE EXTENSION` only in the database that needs it for the test.

#!/bin/bash
# Create additional databases on the same Postgres instance for local dev.
# The default database ($POSTGRES_DB) is created by the image entrypoint before this runs.
#
# The extra databases are read from $POSTGRES_EXTRA_DATABASES — a comma- or
# whitespace-separated list. Defaults to none (only $POSTGRES_DB is created);
# set the variable to create additional databases.
#
# Example:
#   POSTGRES_EXTRA_DATABASES="agent_pipelines,langfuse,analytics"
#
set -euo pipefail

extra_databases="${POSTGRES_EXTRA_DATABASES-}"
read -ra DATABASES <<<"${extra_databases//,/ }"

create_db_if_not_exists() {
    local db="$1"
    psql -X -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-SQL
        SELECT 'CREATE DATABASE ${db}'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db}')
        \gexec
SQL
}

if ((${#DATABASES[@]})); then
    for db in "${DATABASES[@]}"; do
        create_db_if_not_exists "$db"
    done
fi

echo "=== init-databases.sh complete ==="
echo "  Default DB: ${POSTGRES_DB:-app}"
if ((${#DATABASES[@]})); then
    echo "  Extra DBs: ${DATABASES[*]}"
fi

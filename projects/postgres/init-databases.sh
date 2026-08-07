#!/bin/sh
# Create additional local-development databases during first initialization.
set -eu

extra_databases=${POSTGRES_EXTRA_DATABASES-}
database_list=$(printf '%s' "$extra_databases" | tr ',' ' ')
created_databases=
set -f

validate_database_name() {
	db=$1
	case "$db" in
	'' | *[!A-Za-z0-9_]* | [0-9]*)
		printf 'invalid database name: %s\n' "$db" >&2
		return 1
		;;
	esac
}

create_db_if_not_exists() {
	db=$1

	psql -X --set=ON_ERROR_STOP=1 --set=db="$db" \
		--username "$POSTGRES_USER" --dbname postgres <<'SQL'
SELECT format('CREATE DATABASE %I', :'db')
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'db')
\gexec
SQL

	if [ -n "$created_databases" ]; then
		created_databases="$created_databases $db"
	else
		created_databases=$db
	fi
}

for db in $database_list; do
	validate_database_name "$db"
done

for db in $database_list; do
	create_db_if_not_exists "$db"
done

printf '%s\n' '=== init-databases.sh complete ==='
printf '  Default DB: %s\n' "${POSTGRES_DB:-app}"
if [ -n "$created_databases" ]; then
	printf '  Extra DBs: %s\n' "$created_databases"
fi

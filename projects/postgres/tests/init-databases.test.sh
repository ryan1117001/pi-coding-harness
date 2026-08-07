#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$SCRIPT_DIR/../init-databases.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

mkdir "$TMP_DIR/bin"
cat >"$TMP_DIR/bin/psql" <<'MOCK'
#!/bin/sh
set -eu
printf '%s\n' "$*" >>"$PSQL_LOG"
cat >>"$PSQL_INPUT"
printf '%s\n' '---' >>"$PSQL_INPUT"
MOCK
chmod +x "$TMP_DIR/bin/psql"

run_script() {
	: >"$TMP_DIR/psql.log"
	: >"$TMP_DIR/psql.sql"
	PATH="$TMP_DIR/bin:$PATH" \
		PSQL_LOG="$TMP_DIR/psql.log" \
		PSQL_INPUT="$TMP_DIR/psql.sql" \
		POSTGRES_USER=postgres \
		POSTGRES_DB=workspace \
		POSTGRES_EXTRA_DATABASES="${1-}" \
		sh "$SCRIPT"
}

run_script ''
test ! -s "$TMP_DIR/psql.log"

run_script 'analytics'
grep -F -- '--set=db=analytics' "$TMP_DIR/psql.log"
test "$(wc -l <"$TMP_DIR/psql.log" | tr -d ' ')" -eq 1
grep -F "format('CREATE DATABASE %I', :'db')" "$TMP_DIR/psql.sql"
grep -F "datname = :'db'" "$TMP_DIR/psql.sql"

run_script 'agent_pipelines, langfuse analytics_2'
test "$(wc -l <"$TMP_DIR/psql.log" | tr -d ' ')" -eq 3
grep -F -- '--set=db=agent_pipelines' "$TMP_DIR/psql.log"
grep -F -- '--set=db=langfuse' "$TMP_DIR/psql.log"
grep -F -- '--set=db=analytics_2' "$TMP_DIR/psql.log"

for invalid in '2fast' 'quoted"name' 'bad;DROP_DATABASE_workspace' 'with-dash'; do
	if run_script "$invalid" >"$TMP_DIR/invalid.out" 2>"$TMP_DIR/invalid.err"; then
		echo "expected invalid database name to fail: $invalid" >&2
		exit 1
	fi
	grep -F 'invalid database name' "$TMP_DIR/invalid.err"
	test ! -s "$TMP_DIR/psql.log"
done

for invalid_list in 'valid_name,2bad' '*'; do
	if run_script "$invalid_list" >"$TMP_DIR/invalid.out" 2>"$TMP_DIR/invalid.err"; then
		echo "expected invalid database list to fail: $invalid_list" >&2
		exit 1
	fi
	grep -F 'invalid database name' "$TMP_DIR/invalid.err"
	test ! -s "$TMP_DIR/psql.log"
done

printf '%s\n' 'init-databases contract tests passed'

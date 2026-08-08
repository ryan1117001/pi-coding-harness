#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly repo_root
log_prefix='sandbox smoke'
source "$repo_root/tools/lib/shell.sh"
load_toolchain "$repo_root/tools/toolchain.env"

readonly launcher="$repo_root/.sandbox/launch-pi.sh"
readonly name="pi-sbx-smoke-$(date -u +%Y%m%d%H%M%S)-$$"
tmp_root="$(cd "$(mktemp -d)" && pwd -P)"
readonly tmp_root
readonly state_root="$tmp_root/state"
readonly settings="$tmp_root/settings.json"
readonly extensions="$tmp_root/extensions"
# Only the two built-in variants may appear in the template cache; custom save,
# load, tag and export are prohibited.
readonly allowed_templates='[["docker.io/docker/sandbox-templates","shell"],["docker.io/docker/sandbox-templates","shell-docker"]]'
created=0
baseline_sandboxes=''
baseline_policies=''

assert_no_custom_template() {
	sbx template ls --json | python3 -c '
import json, sys
allowed = {tuple(pair) for pair in json.loads(sys.argv[1])}
for image in json.load(sys.stdin).get("images", []):
    pair = (image.get("repository"), image.get("tag"))
    if pair not in allowed:
        raise SystemExit(f"unexpected custom template: {pair}")
' "$allowed_templates"
}

cleanup() {
	local status=$?
	trap - EXIT INT TERM
	set +e
	if [[ "$created" -eq 1 ]]; then
		SANDBOX_STATE_ROOT="$state_root" "$launcher" --remove "$name" || status=1
	fi
	rm -rf -- "$tmp_root"
	if [[ -n "$baseline_sandboxes" && "$(sbx ls --json)" != "$baseline_sandboxes" ]]; then
		warn 'sandbox inventory differs after cleanup'
		status=1
	fi
	if [[ -n "$baseline_policies" && "$(sbx policy ls --include-inactive --json)" != "$baseline_policies" ]]; then
		warn 'policy inventory differs after cleanup'
		status=1
	fi
	# Checked here rather than inline so a mid-run failure still proves it.
	if ! assert_no_custom_template; then
		warn 'template cache contains an unexpected entry'
		status=1
	fi
	if [[ "$status" -eq 0 ]]; then
		printf 'Disposable Docker Sandbox smoke passed and invocation-owned resources were removed.\n'
	fi
	exit "$status"
}
install_standard_traps

[[ "${SANDBOX_LIVE_SMOKE:-0}" == 1 ]] || fail 'set SANDBOX_LIVE_SMOKE=1 only on an eligible, explicitly authorized host'
require_sbx_version
[[ "$(sbx ls --json)" == *'"sandboxes"'* ]] || fail 'sandbox inventory unavailable'
baseline_sandboxes="$(sbx ls --json)"
baseline_policies="$(sbx policy ls --include-inactive --json)"
readonly baseline_sandboxes baseline_policies
assert_no_custom_template || fail 'template cache was not clean before the smoke'

# Value-free inventory only. A global OpenAI credential makes provider smoke ineligible.
if sbx secret ls --global | grep -Eq '(^|[[:space:]])openai([[:space:]]|$)'; then
	printf 'Provider smoke refused: a pre-existing global OpenAI credential could satisfy it.\n'
fi

mkdir -p "$extensions"
printf '{"packages": []}\n' >"$settings"
printf 'export default {}\n' >"$extensions/smoke.ts"

SANDBOX_STATE_ROOT="$state_root" \
	PI_USER_SETTINGS="$settings" \
	PI_USER_EXTENSIONS="$extensions" \
	SANDBOX_SKIP_BROWSER="${SANDBOX_SKIP_BROWSER:-0}" \
	"$launcher" --name "$name" --docker --with-user-pi --detached
created=1

# The private clone is mounted at the same absolute path as the host source, so
# the recorded staging path is also the in-sandbox working directory.
workspace="$(cat "$state_root/$name/staging-path")"
readonly workspace

sbx exec -w "$workspace" \
	-e "EXPECTED_PI=$EXPECTED_PI" \
	-e "EXPECTED_NODE=$EXPECTED_NODE" \
	-e "EXPECTED_PNPM=$EXPECTED_PNPM" \
	-e "EXPECTED_PYTHON=$EXPECTED_PYTHON" \
	-e "EXPECTED_UV=$EXPECTED_UV" \
	"$name" sh -lc '
set -eu
test "$(pi --version)" = "$EXPECTED_PI"
test "$(node --version)" = "$EXPECTED_NODE"
test "$(pnpm --version)" = "$EXPECTED_PNPM"
test "$(python --version 2>&1)" = "$EXPECTED_PYTHON"
test "$(uv --version | cut -d" " -f1-2)" = "$EXPECTED_UV"
test -L "$HOME/.pi/agent/settings.json"
test -L "$HOME/.pi/agent/extensions"
test ! -w "$HOME/.pi/agent/settings.json"
test ! -e "$HOME/.pi/agent/auth.json"
test -S /var/run/docker.sock
docker info >/dev/null
test -z "$(docker ps -aq)"
test -z "$(docker image ls -q)"
'

settings_source="$state_root/$name/settings-input/settings.json"
extensions_source="$(cd "$extensions" && pwd -P)"
if [[ "${SANDBOX_SKIP_BROWSER:-0}" != 1 ]]; then
	sbx exec -w "$workspace" "$name" node --input-type=module -e \
		'import { chromium } from "playwright"; const browser = await chromium.launch({headless:true}); await browser.close();'
fi

# Re-running the bootstrap must be idempotent and must not dirty the clone.
before_status="$(sbx exec -w "$workspace" "$name" git status --short)"
[[ -z "$before_status" ]] || fail 'sandbox clone was dirty before the idempotence check'
sbx exec -w "$workspace" \
	-e "SANDBOX_PI_SETTINGS_SOURCE=$settings_source" \
	-e "SANDBOX_PI_EXTENSIONS_SOURCE=$extensions_source" \
	-e SANDBOX_SKIP_BROWSER=1 \
	"$name" bash .sandbox/bootstrap-pi.sh user
after_status="$(sbx exec -w "$workspace" "$name" git status --short)"
[[ "$after_status" == "$before_status" ]] || fail 'repeated bootstrap dirtied the sandbox clone'

sbx exec -w "$workspace" "$name" sh -lc '
set -eu
for path in "$HOME/.local" "$HOME/.cache" "$HOME/.pi" "$PWD/node_modules"; do
  test -z "$(find "$path" -xdev -user root -print -quit 2>/dev/null)"
done
'

# Copy/recovery does not expose upstream Git credentials.
printf 'host-to-sandbox\n' >"$tmp_root/host.txt"
sbx cp "$tmp_root/host.txt" "$name:/tmp/host.txt"
sbx exec "$name" grep -Fxq host-to-sandbox /tmp/host.txt
sbx exec "$name" sh -lc 'printf "sandbox-to-host\n" >/tmp/sandbox.txt'
sbx cp "$name:/tmp/sandbox.txt" "$tmp_root/recovered.txt"
grep -Fxq sandbox-to-host "$tmp_root/recovered.txt"

# No outer application/database publication is present by default.
sbx ports "$name" --json | python3 -c '
import json, sys
for item in json.load(sys.stdin):
    if item.get("sandbox_port") in {4200, 5432, 8000}:
        raise SystemExit("unexpected default application/database publication")
'

sbx exec -w "$workspace" "$name" sh -lc 'docker compose -f compose.yml config --quiet'
if [[ "${SANDBOX_SMOKE_COMPOSE:-0}" == 1 ]]; then
	sbx exec -w "$workspace" "$name" sh -lc \
		'docker compose -f compose.yml up -d --wait postgres && docker compose -f compose.yml down --volumes'
fi

SANDBOX_STATE_ROOT="$state_root" "$launcher" --remove "$name"
created=0

[[ "$(sbx ls --json)" == "$baseline_sandboxes" ]] || fail 'sandbox inventory differs after removal'
[[ "$(sbx policy ls --include-inactive --json)" == "$baseline_policies" ]] || fail 'policy inventory differs after removal'

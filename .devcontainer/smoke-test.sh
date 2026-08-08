#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly repo_root
log_prefix='devcontainer smoke'
source "$repo_root/tools/lib/shell.sh"
load_toolchain "$repo_root/tools/toolchain.env"

cd "$repo_root"

readonly compose_files=(-f compose.yml -f .devcontainer/compose.yml)
# Compose renders the workspace bind from localWorkspaceFolder. Inside the
# container the host path is unknowable, so every invocation here uses the same
# placeholder and is limited to inspection subcommands.
readonly compose_workspace_folder='.'
api_log="$(mktemp)"
readonly api_log
web_log="$(mktemp)"
readonly web_log
state_snapshot="$(mktemp)"
readonly state_snapshot
readonly tracked_state=(pnpm-lock.yaml projects/api/uv.lock projects/web/src/routeTree.gen.ts)
api_pid=''
web_pid=''

workspace_compose() {
	localWorkspaceFolder="$compose_workspace_folder" docker compose "${compose_files[@]}" "$@"
}

stop_process_group() {
	local pid="$1"
	local label="$2"
	local deadline=$((SECONDS + 10))

	[[ -n "$pid" ]] || return 0
	kill -TERM -- "-$pid" 2>/dev/null || true
	while kill -0 -- "-$pid" 2>/dev/null && ((SECONDS < deadline)); do
		sleep 0.2
	done
	if kill -0 -- "-$pid" 2>/dev/null; then
		printf 'Force-stopping lingering %s process group %s\n' "$label" "$pid" >&2
		kill -KILL -- "-$pid" 2>/dev/null || true
		deadline=$((SECONDS + 5))
		while kill -0 -- "-$pid" 2>/dev/null && ((SECONDS < deadline)); do
			sleep 0.2
		done
	fi
	wait "$pid" 2>/dev/null || true
	if kill -0 -- "-$pid" 2>/dev/null; then
		printf 'Failed to stop %s process group %s\n' "$label" "$pid" >&2
		return 1
	fi
}

cleanup() {
	local status=$?
	trap - EXIT INT TERM
	set +e
	local cleanup_status=0
	stop_process_group "$web_pid" web || cleanup_status=1
	stop_process_group "$api_pid" API || cleanup_status=1
	if [[ "$cleanup_status" -ne 0 && "$status" -eq 0 ]]; then
		status=1
	fi
	if [[ "$status" -eq 0 ]]; then
		printf 'Dev Container smoke test passed.\n'
	else
		printf '\nAPI log:\n' >&2
		cat "$api_log" >&2
		printf '\nWeb log:\n' >&2
		cat "$web_log" >&2
		workspace_compose ps >&2
	fi
	rm -f "$api_log" "$web_log" "$state_snapshot"
	exit "$status"
}
install_standard_traps

[[ "$(id -u)" -ne 0 ]] || fail 'smoke must run as the non-root remote user'
assert_toolchain

[[ -d "$HOME/.pi/agent" && -w "$HOME/.pi/agent" ]] || fail 'Pi agent root is not writable'
agent_write_probe="$HOME/.pi/agent/.devcontainer-write-test-$$"
touch "$agent_write_probe"
rm -f "$agent_write_probe"

# Each Pi state path must be its own named volume, so nothing leaks between the
# project and global package/worktree trees.
readonly pi_state_paths=(
	"$HOME/.pi/agent/npm"
	"$HOME/.pi/agent/git"
	"$PWD/.pi/npm"
	"$PWD/.pi/git"
)
pi_mount_sources=()
for state_path in "${pi_state_paths[@]}"; do
	[[ -d "$state_path" && -w "$state_path" ]] || fail "Pi state path is not writable: $state_path"
	mountpoint --quiet "$state_path" || fail "Pi state path is not a mount: $state_path"
	write_probe="$state_path/.devcontainer-write-test-$$"
	touch "$write_probe"
	rm -f "$write_probe"
	pi_mount_sources+=("$(findmnt --target "$state_path" --noheadings --output SOURCE)")
done
[[ "$(printf '%s\n' "${pi_mount_sources[@]}" | sort -u | wc -l | tr -d ' ')" -eq "${#pi_state_paths[@]}" ]] ||
	fail 'Pi state paths do not resolve to distinct volumes'

sha256sum "${tracked_state[@]}" >"$state_snapshot"

CI=true pnpm install --frozen-lockfile
uv sync --project projects/api --locked

projects="$(pnpm exec nx show projects)"
readonly projects
for project in api postgres web web-e2e; do
	grep -Fxq "$project" <<<"$projects" || fail "missing Nx project: $project"
done

node --input-type=module - <<'NODE'
import { chromium } from 'playwright';
const browser = await chromium.launch({ headless: true });
await browser.close();
NODE

docker info >/dev/null
workspace_compose config --quiet
workspace_compose exec -T postgres \
	pg_isready -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-workspace}" >/dev/null

setsid bash -lc 'exec pnpm exec nx serve api' >"$api_log" 2>&1 &
api_pid=$!
wait_for_url 'http://127.0.0.1:8000/api/v1/health/ready' 90

setsid bash -lc 'exec pnpm exec nx serve web' >"$web_log" 2>&1 &
web_pid=$!
wait_for_url 'http://localhost:4200/' 90

# Nothing above may rewrite a lockfile or a generated tracked file.
sha256sum --check "$state_snapshot"

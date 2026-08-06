#!/usr/bin/env bash
set -Eeuo pipefail

readonly EXPECTED_NODE='v24.18.0'
readonly EXPECTED_PNPM='11.15.1'
readonly EXPECTED_PYTHON='Python 3.14.3'
readonly EXPECTED_UV='uv 0.11.14'
readonly EXPECTED_PI='0.83.0'
readonly PI_PACKAGE='@earendil-works/pi-coding-agent@0.83.0'

fail() {
	printf 'devcontainer setup: %s\n' "$*" >&2
	exit 1
}

assert_version() {
	local label="$1"
	local expected="$2"
	local actual="$3"
	[[ "$actual" == "$expected" ]] || fail "$label version mismatch: expected '$expected', found '$actual'"
}

[[ "$(id -u)" -ne 0 ]] || fail 'setup must run as the non-root remote user'

assert_version Node "$EXPECTED_NODE" "$(node --version)"
assert_version Python "$EXPECTED_PYTHON" "$(python --version 2>&1)"
assert_version uv "$EXPECTED_UV" "$(uv --version | cut -d' ' -f1-2)"

readonly pi_agent_parent_paths=(
	"$HOME/.pi"
	"$HOME/.pi/agent"
)

readonly volume_paths=(
	"$HOME/.local/share/pnpm"
	"$HOME/.local/share/pnpm/bin"
	"$HOME/.local/share/pnpm/store"
	"$HOME/.cache/node"
	"$HOME/.cache/uv"
	"$HOME/.cache/ms-playwright"
	"$HOME/.pi/agent/npm"
	"$HOME/.pi/agent/git"
	"$PWD/node_modules"
	"$PWD/projects/web/node_modules"
	"$PWD/projects/web-e2e/node_modules"
	"$PWD/projects/api/node_modules"
	"$PWD/projects/postgres/node_modules"
	"$PWD/projects/api/.venv"
	"$PWD/.nx"
	"$PWD/.pi/npm"
	"$PWD/.pi/git"
)

sudo mkdir -p "${pi_agent_parent_paths[@]}" "${volume_paths[@]}"
# Do not recurse through the agent root: opted-in host settings and extensions are read-only binds.
sudo chown "$(id -u):$(id -g)" "${pi_agent_parent_paths[@]}"
sudo chown -R "$(id -u):$(id -g)" "${volume_paths[@]}"
assert_version pnpm "$EXPECTED_PNPM" "$(pnpm --version)"

if ! command -v pi >/dev/null 2>&1 || [[ "$(pi --version 2>/dev/null || true)" != "$EXPECTED_PI" ]]; then
	printf 'Installing %s...\n' "$PI_PACKAGE"
	pnpm add --global "$PI_PACKAGE"
fi
assert_version Pi "$EXPECTED_PI" "$(pi --version)"

printf 'Restoring locked workspace dependencies...\n'
CI=true pnpm install --frozen-lockfile
uv sync --project projects/api --locked

printf 'Installing Chromium system dependencies and browser...\n'
sudo env "PATH=$PATH" pnpm exec playwright install-deps chromium
pnpm exec playwright install chromium

printf 'Dev Container setup complete.\n'

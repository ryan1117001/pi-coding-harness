#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly repo_root
log_prefix='devcontainer setup'
source "$repo_root/tools/lib/shell.sh"
load_toolchain "$repo_root/tools/toolchain.env"

cd "$repo_root"

[[ "$(id -u)" -ne 0 ]] || fail 'setup must run as the non-root remote user'

assert_version Node "$EXPECTED_NODE" "$(node --version)"
assert_version Python "$EXPECTED_PYTHON" "$(python --version 2>&1)"
assert_version uv "$EXPECTED_UV" "$(uv --version | cut -d' ' -f1-2)"

# The agent root and its parent are created but not recursed into: opted-in host
# settings and extensions arrive as read-only binds underneath them.
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
sudo chown "$(id -u):$(id -g)" "${pi_agent_parent_paths[@]}"
sudo chown -R "$(id -u):$(id -g)" "${volume_paths[@]}"

# pnpm is asserted only after the chown above creates its writable home.
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

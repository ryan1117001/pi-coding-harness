#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly repo_root
log_prefix='sandbox bootstrap'
source "$repo_root/tools/lib/shell.sh"

install_node() {
	local version="${EXPECTED_NODE#v}"
	local destination="$HOME/.local/node-v$version"
	rm -rf -- "$destination"
	mkdir -p "$destination" "$HOME/.local/bin"
	# The exact npm package and its architecture package are integrity-verified by npm
	# and avoid bypassing the sandbox/enterprise TLS trust chain.
	NPM_CONFIG_PREFIX="$destination" npm install --global "node@$version"
	[[ -x "$destination/bin/node" ]] || fail 'pinned Node package did not install a binary'
	ln -sfn "$destination/bin/node" "$HOME/.local/bin/node"
}

install_uv() {
	python3 -m pip install --user --break-system-packages --no-cache-dir "uv==${EXPECTED_UV#uv }"
	[[ -x "$HOME/.local/bin/uv" ]] || fail 'pinned uv wheel did not install a binary'
}

# Link one read-only mounted input into the sandbox-local agent root. Re-running
# the bootstrap must be idempotent, so an existing link is accepted only when it
# already points at the expected input.
link_user_pi_input() {
	local name="$1"
	local source="$2"
	local kind="$3"
	local agent_root="$HOME/.pi/agent"

	[[ -n "$source" ]] || return 0
	case "$kind" in
	file) [[ -f "$source" ]] || fail "mounted $name input is unavailable" ;;
	directory) [[ -d "$source" ]] || fail "mounted $name input is unavailable" ;;
	*) fail "unknown input kind: $kind" ;;
	esac
	if [[ -L "$agent_root/$name" ]]; then
		[[ "$(readlink "$agent_root/$name")" == "$source" ]] ||
			fail "sandbox $name symlink targets an unexpected input"
		return 0
	fi
	[[ ! -e "$agent_root/$name" ]] || fail "sandbox $name path already exists"
	ln -s "$source" "$agent_root/$name"
}

wire_user_pi_inputs() {
	mkdir -p "$HOME/.pi/agent"
	link_user_pi_input 'settings.json' "${SANDBOX_PI_SETTINGS_SOURCE:-}" file
	link_user_pi_input 'extensions' "${SANDBOX_PI_EXTENSIONS_SOURCE:-}" directory
}

case "${1:-user}" in
system)
	[[ "$(id -u)" -eq 0 ]] || fail 'system phase must run as root'
	export DEBIAN_FRONTEND=noninteractive
	apt-get update
	apt-get install --yes --no-install-recommends ca-certificates curl git xz-utils
	rm -rf /var/lib/apt/lists/*
	for command in curl git sha256sum tar xz; do
		command -v "$command" >/dev/null 2>&1 || fail "required base command missing: $command"
	done
	exit 0
	;;
user)
	[[ "$(id -u)" -ne 0 ]] || fail 'user phase must not run as root'
	;;
*)
	fail "unknown phase: $1"
	;;
esac

load_toolchain "$repo_root/tools/toolchain.env"

export PNPM_HOME="$HOME/.local/share/pnpm"
readonly pnpm_bin_dir="$PNPM_HOME/bin"
mkdir -p "$HOME/.local/bin" "$HOME/.cache" "$pnpm_bin_dir"
# The sandbox image ships its own older node/uv under /usr/local; prepending the
# per-user prefixes is what makes the pinned versions win.
export PATH="$HOME/.local/bin:$pnpm_bin_dir:$PATH"
export UV_CACHE_DIR="$HOME/.cache/uv"
export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/ms-playwright"

if ! command -v node >/dev/null 2>&1 || [[ "$(node --version)" != "$EXPECTED_NODE" ]]; then
	install_node
fi
assert_version Node "$EXPECTED_NODE" "$(node --version)"

if ! command -v pnpm >/dev/null 2>&1 || [[ "$(pnpm --version 2>/dev/null || true)" != "$EXPECTED_PNPM" ]]; then
	NPM_CONFIG_PREFIX="$HOME/.local" npm install --global "pnpm@$EXPECTED_PNPM"
	ln -sfn "$HOME/.local/bin/pnpm" "$pnpm_bin_dir/pnpm" 2>/dev/null || true
fi
assert_version pnpm "$EXPECTED_PNPM" "$(pnpm --version)"

if ! command -v uv >/dev/null 2>&1 || [[ "$(uv --version | cut -d' ' -f1-2)" != "$EXPECTED_UV" ]]; then
	install_uv
fi
assert_version uv "$EXPECTED_UV" "$(uv --version | cut -d' ' -f1-2)"

assert_version Python "$EXPECTED_PYTHON" "$(python3 --version 2>&1)"
python_path="$(command -v python3)"
readonly python_path
ln -sfn "$python_path" "$HOME/.local/bin/python"
assert_version Python "$EXPECTED_PYTHON" "$(python --version 2>&1)"

pi_destination="$HOME/.local/pi-$EXPECTED_PI"
if [[ ! -x "$pi_destination/bin/pi" ]] || [[ "$($pi_destination/bin/pi --version 2>/dev/null || true)" != "$EXPECTED_PI" ]]; then
	rm -rf -- "$pi_destination"
	NPM_CONFIG_PREFIX="$pi_destination" npm install --global "$PI_PACKAGE"
fi
ln -sfn "$pi_destination/bin/pi" "$HOME/.local/bin/pi"
assert_version Pi "$EXPECTED_PI" "$(pi --version)"

profile_line='export PNPM_HOME="$HOME/.local/share/pnpm"'
path_line='export PATH="$HOME/.local/bin:$PNPM_HOME/bin:$PATH"'
touch "$HOME/.profile"
grep -Fqx "$profile_line" "$HOME/.profile" || printf '%s\n' "$profile_line" >>"$HOME/.profile"
grep -Fqx "$path_line" "$HOME/.profile" || printf '%s\n' "$path_line" >>"$HOME/.profile"

wire_user_pi_inputs

CI=true pnpm install --frozen-lockfile
uv sync --project projects/api --locked

if [[ "${SANDBOX_SKIP_BROWSER:-0}" != 1 ]]; then
	pnpm exec playwright install-deps chromium
	pnpm exec playwright install chromium
fi

assert_toolchain
printf 'Sandbox bootstrap complete.\n'

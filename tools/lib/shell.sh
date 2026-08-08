# Shared helpers for the Dev Container and Docker Sandbox shell entrypoints.
#
# Sourced, never executed. Callers set `log_prefix` to label their diagnostics,
# then source this file:
#
#     log_prefix='sandbox launcher'
#     source "$repo_root/tools/lib/shell.sh"
#
# Every helper here fails closed: a missing tool or a version that does not match
# the pinned authority aborts rather than continuing on a downgraded toolchain.

log_prefix="${log_prefix:-harness}"

fail() {
	printf '%s: %s\n' "$log_prefix" "$*" >&2
	exit 1
}

warn() {
	printf '%s: %s\n' "$log_prefix" "$*" >&2
}

assert_version() {
	local label="$1"
	local expected="$2"
	local actual="$3"
	[[ "$actual" == "$expected" ]] || fail "$label version mismatch: expected '$expected', found '$actual'"
}

# Install the conventional trap set. The caller's cleanup function name is
# optional and defaults to `cleanup`. INT and TERM exit with their signal codes
# so the EXIT trap still runs exactly once.
install_standard_traps() {
	local cleanup_function="${1:-cleanup}"
	trap "$cleanup_function" EXIT
	trap 'exit 130' INT
	trap 'exit 143' TERM
}

# Read tools/toolchain.env and derive EXPECTED_PI from PI_PACKAGE so the package
# string stays the single authority. Callers must not re-hardcode either value.
load_toolchain() {
	local authority="$1"
	[[ -f "$authority" && ! -L "$authority" ]] || fail "missing toolchain authority: $authority"
	# shellcheck disable=SC1090
	source "$authority"
	local required
	for required in EXPECTED_NODE EXPECTED_PNPM EXPECTED_PYTHON EXPECTED_UV PI_PACKAGE; do
		[[ -n "${!required:-}" ]] || fail "toolchain authority does not define $required"
	done
	[[ "$PI_PACKAGE" =~ ^@earendil-works/pi-coding-agent@[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
		fail "malformed Pi authority: $PI_PACKAGE"
	EXPECTED_PI="${PI_PACKAGE##*@}"
}

# Assert the complete pinned toolchain. Callers that provision tools in stages
# use assert_version directly for the subset that is ready.
assert_toolchain() {
	assert_version Node "$EXPECTED_NODE" "$(node --version)"
	assert_version pnpm "$EXPECTED_PNPM" "$(pnpm --version)"
	assert_version Python "$EXPECTED_PYTHON" "$(python --version 2>&1)"
	assert_version uv "$EXPECTED_UV" "$(uv --version | cut -d' ' -f1-2)"
	assert_version Pi "$EXPECTED_PI" "$(pi --version)"
}

# Enforce a minimum sbx version rather than an exact pin, so the launcher keeps
# working on releases newer than the one the lifecycle forms were recorded
# against. Anything above SBX_VERIFIED runs with a single warning.
require_sbx_version() {
	command -v sbx >/dev/null 2>&1 || fail 'sbx is not installed'
	local reported=''
	reported="$(sbx version 2>&1)" || fail 'unable to read sbx version'
	local found=''
	found="$(sed -n 's/^sbx version: v\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\).*/\1/p' <<<"$reported")"
	[[ -n "$found" ]] || fail "unable to parse sbx version from: $reported"
	local lowest
	lowest="$(printf '%s\n%s\n' "$SBX_MINIMUM" "$found" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)"
	[[ "$lowest" == "$SBX_MINIMUM" ]] || fail "requires sbx $SBX_MINIMUM or newer; found $found"
	if [[ "$found" != "$SBX_VERIFIED" ]]; then
		warn "sbx $found is newer than the verified $SBX_VERIFIED; lifecycle forms are unverified above $SBX_VERIFIED"
	fi
}

wait_for_url() {
	local url="$1"
	local attempts="${2:-60}"
	local attempt
	for ((attempt = 1; attempt <= attempts; attempt++)); do
		if curl --fail --silent --show-error "$url" >/dev/null 2>&1; then
			return 0
		fi
		sleep 1
	done
	fail "timed out waiting for $url"
}

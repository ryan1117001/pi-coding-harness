#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly script_dir
repo_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
readonly repo_root
log_prefix='sandbox launcher'
source "$repo_root/tools/lib/shell.sh"
load_toolchain "$repo_root/tools/toolchain.env"

readonly contract="$script_dir/sandbox_contract.py"
readonly shell_template='docker.io/docker/sandbox-templates:shell'
readonly shell_docker_template='docker.io/docker/sandbox-templates:shell-docker'

state_root="${SANDBOX_STATE_ROOT:-$HOME/.local/state/pi-coding-harness/sandboxes}"

readonly default_bootstrap_network=(
	'registry.npmjs.org:443'
	'pypi.org:443'
	'files.pythonhosted.org:443'
	'download.docker.com:443'
	'archive.ubuntu.com:80'
	'security.ubuntu.com:80'
	'ports.ubuntu.com:80'
)
readonly default_browser_network=(
	'cdn.playwright.dev:443'
	'playwright.download.prss.microsoft.com:443'
	'playwright.azureedge.net:443'
)
# Both built-in templates attach their own uneditable `kit:<sandbox>` allow at
# create time. It is acknowledged rather than owned: the launcher never adds or
# removes it, and it disappears with the sandbox.
readonly default_template_network=(
	'openrouter.ai:443'
)

name=''
attach_name=''
remove_name=''
workspace_mode='clone'
use_docker=0
with_user_pi=0
trusted_direct=0
detached=0
bootstrap=1
staging_path=''
state_dir=''
settings_source=''
extensions_source=''
template=''
policy_ids=()
bootstrap_network=()
template_network=()
extra_workspaces=()

usage() {
	cat <<'USAGE'
Usage:
  .sandbox/launch-pi.sh [--name NAME] [--docker] [--direct --trust-direct]
                        [--with-user-pi] [--detached] [--no-bootstrap]
  .sandbox/launch-pi.sh --attach NAME [--detached]
  .sandbox/launch-pi.sh --remove NAME

Clone mode is the default and selects a unique standalone tracked-only clone
of repository HEAD. Direct mode exposes the entire selected checkout read/write
and must be explicitly trusted. --docker selects the sandbox-local Docker Engine
variant. No outer application, database, or provider credential setup is
supported.
USAGE
}

sandbox_json() {
	sbx ls --json
}

sandbox_present() {
	sandbox_json | python3 "$contract" sandbox-present "$1"
}

# Sandbox-scoped, not global: `sbx policy ls` without a name returns one overview
# row per policy, which cannot prove a scoped rule is gone.
policy_id_absent() {
	sbx policy ls "$name" --include-inactive --json |
		python3 "$contract" policy-rule-absent "$1"
}

rewrite_policy_state() {
	[[ -n "$state_dir" && -f "$state_dir/policy-ids" ]] || return 0
	if ((${#policy_ids[@]})); then
		printf '%s\n' "${policy_ids[@]}" | awk 'NF && !seen[$0]++' >"$state_dir/policy-ids.tmp"
	else
		: >"$state_dir/policy-ids.tmp"
	fi
	mv "$state_dir/policy-ids.tmp" "$state_dir/policy-ids"
}

remove_policy_ids() {
	local id=''
	local -a remaining=()
	local failed=0
	for id in "${policy_ids[@]}"; do
		[[ -n "$id" ]] || continue
		if ! sbx policy rm network --sandbox "$name" --id "$id"; then
			warn "failed to remove policy rule $id; ownership state retained"
			remaining+=("$id")
			failed=1
		elif ! policy_id_absent "$id"; then
			warn "policy rule $id is still present or absence could not be proved; ownership state retained"
			remaining+=("$id")
			failed=1
		fi
	done
	policy_ids=("${remaining[@]}")
	rewrite_policy_state
	return "$failed"
}

state_dir_is_owned() {
	[[ -n "$name" && -n "$state_dir" && "$state_dir" == "$state_root/$name" ]] || return 1
	[[ -d "$state_dir" && ! -L "$state_dir" && -f "$state_dir/.owner" ]] || return 1
	[[ "$(cat "$state_dir/.owner")" == "$name" ]]
}

remove_staging_clone() {
	[[ "$workspace_mode" == clone && -n "$staging_path" ]] || return 0
	state_dir_is_owned && [[ "$staging_path" == "$state_dir/source-clone" ]] || {
		warn "refusing to remove unexpected clone path: $staging_path"
		return 1
	}
	rm -rf -- "$staging_path"
}

cleanup_failed_create() {
	local status=$?
	local cleanup_failed=0
	trap - EXIT INT TERM
	set +e
	if [[ "$status" -ne 0 && -n "$name" && -n "$state_dir" ]]; then
		remove_policy_ids || cleanup_failed=1
		local inventory=''
		if ! inventory="$(sandbox_json)"; then
			warn "cannot inventory $name after failed create; ownership state retained"
			cleanup_failed=1
		elif python3 "$contract" sandbox-present "$name" <<<"$inventory"; then
			if ! record_created_sandbox; then
				warn "partially created sandbox $name does not match its recorded contract; ownership state retained"
				cleanup_failed=1
			elif ! sbx rm "$name" --force; then
				warn "failed to remove partially created sandbox $name; ownership state retained"
				cleanup_failed=1
			elif ! inventory="$(sandbox_json)"; then
				warn "cannot prove sandbox $name absent after removal; ownership state retained"
				cleanup_failed=1
			elif python3 "$contract" sandbox-present "$name" <<<"$inventory"; then
				warn "sandbox $name remains after removal; ownership state retained"
				cleanup_failed=1
			fi
		fi
		if [[ "$cleanup_failed" -eq 0 && ${#policy_ids[@]} -eq 0 ]]; then
			if [[ "$workspace_mode" == clone && -n "$staging_path" ]]; then
				remove_staging_clone || cleanup_failed=1
			fi
			[[ "$cleanup_failed" -ne 0 ]] || { state_dir_is_owned && rm -rf -- "$state_dir"; }
		fi
		[[ "$cleanup_failed" -eq 0 ]] ||
			warn "cleanup incomplete; retry with --remove $name after resolving the reported failure"
	fi
	exit "$status"
}

assert_clean_tracked_source() {
	local source="$1"
	[[ -d "$source/.git" && ! -L "$source/.git" ]] || fail 'generated source is not a standalone Git clone'
	[[ "$(git -C "$source" rev-parse HEAD)" == "$(git -C "$repo_root" rev-parse HEAD)" ]] ||
		fail 'generated source is not repository HEAD'
	[[ -z "$(git -C "$source" status --porcelain=v1 --untracked-files=all --ignored)" ]] ||
		fail 'generated standalone clone contains untracked or ignored state'
	python3 "$contract" clean-source "$source" || fail 'generated standalone clone failed its content contract'
}

prepare_user_pi() {
	local host_settings="${PI_USER_SETTINGS:-$HOME/.pi/agent/settings.json}"
	local host_extensions="${PI_USER_EXTENSIONS:-$HOME/.pi/agent/extensions}"
	[[ -f "$host_settings" && ! -L "$host_settings" ]] || fail 'user settings must be a regular non-symlink file'
	[[ -d "$host_extensions" && ! -L "$host_extensions" ]] ||
		fail 'user extensions must be a directory whose root is not a symlink'
	local snapshot_dir="$state_dir/settings-input"
	mkdir -m 700 "$snapshot_dir"
	python3 "$contract" snapshot-settings "$host_settings" "$snapshot_dir/settings.json"
	settings_source="$snapshot_dir"
	extensions_source="$(cd "$host_extensions" && pwd -P)"
}

add_policy_rule() {
	local resource="$1"
	local output=''
	output="$(sbx policy allow network --sandbox "$name" "$resource")"
	local id=''
	id="$(grep -Eo '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' <<<"$output" | tail -n1)"
	[[ -n "$id" ]] || fail "could not record policy rule ID for $resource"
	policy_ids+=("$id")
	printf '%s\n' "$id" >>"$state_dir/policy-ids"
	sbx policy check network --sandbox "$name" "$resource" --json >/dev/null
}

wire_user_pi() {
	[[ -n "$settings_source" ]] || return 0
	sbx exec \
		-e "SANDBOX_PI_SETTINGS_SOURCE=$settings_source/settings.json" \
		-e "SANDBOX_PI_EXTENSIONS_SOURCE=$extensions_source" \
		"$name" sh -lc '
set -eu
mkdir -p "$HOME/.pi/agent"
test ! -e "$HOME/.pi/agent/settings.json" && test ! -L "$HOME/.pi/agent/settings.json"
test ! -e "$HOME/.pi/agent/extensions" && test ! -L "$HOME/.pi/agent/extensions"
ln -s "$SANDBOX_PI_SETTINGS_SOURCE" "$HOME/.pi/agent/settings.json"
ln -s "$SANDBOX_PI_EXTENSIONS_SOURCE" "$HOME/.pi/agent/extensions"
test ! -w "$HOME/.pi/agent/settings.json"
'
}

load_network_contract() {
	bootstrap_network=()
	template_network=()
	if [[ -n "${SANDBOX_BOOTSTRAP_NETWORK:-}" ]]; then
		IFS=',' read -r -a bootstrap_network <<<"$SANDBOX_BOOTSTRAP_NETWORK"
	else
		bootstrap_network=("${default_bootstrap_network[@]}")
		if [[ "${SANDBOX_SKIP_BROWSER:-0}" != 1 ]]; then
			bootstrap_network+=("${default_browser_network[@]}")
		fi
	fi
	if [[ -n "${SANDBOX_EXPECTED_TEMPLATE_NETWORK:-}" ]]; then
		IFS=',' read -r -a template_network <<<"$SANDBOX_EXPECTED_TEMPLATE_NETWORK"
	else
		template_network=("${default_template_network[@]}")
	fi
	python3 "$contract" validate-network 'bootstrap network' "${bootstrap_network[@]}" ||
		fail 'bootstrap network contract is invalid'
	python3 "$contract" validate-network 'expected template network' "${template_network[@]}" ||
		fail 'expected template network contract is invalid'
}

assert_denied() {
	local resource="$1"
	if sbx policy check network --sandbox "$name" "$resource" --json >/dev/null 2>&1; then
		fail "unexpected effective network authorization: $resource"
	fi
}

assert_effective_policy() {
	local inventory=''
	inventory="$(sbx policy ls "$name" --include-inactive --json)" || fail 'effective policy inventory unavailable'
	printf '%s\n' "$inventory" >"$state_dir/effective-policy.json"

	local acknowledged_csv owned_id_csv owned_resource_csv
	acknowledged_csv="$(
		IFS=,
		printf '%s' "${template_network[*]}"
	)"
	owned_id_csv="$(
		IFS=,
		printf '%s' "${policy_ids[*]}"
	)"
	owned_resource_csv="$(
		IFS=,
		printf '%s' "${bootstrap_network[*]}"
	)"

	local seen_template=''
	seen_template="$(
		python3 "$contract" policy-effective \
			"$acknowledged_csv" "$owned_id_csv" "$owned_resource_csv" <<<"$inventory"
	)" || fail 'effective network policy violates the invocation contract'

	# Positively check only what is actually in force: the template rules the
	# contract observed, plus this invocation's own rules once they are added.
	local -a effective=()
	local line
	while IFS= read -r line; do [[ -z "$line" ]] || effective+=("$line"); done <<<"$seen_template"
	((${#policy_ids[@]} == 0)) || effective+=("${bootstrap_network[@]}")

	local resource host port alternate
	for resource in ${effective[@]+"${effective[@]}"}; do
		sbx policy check network --sandbox "$name" "$resource" --json >/dev/null ||
			fail "approved network resource is not effective: $resource"
	done

	# An exact `host:port` rule — the only form this launcher adds — denies every
	# other port on that host. A template's host-only rule does not: it covers all
	# ports. So the alternate-port probe applies to owned rules only.
	if ((${#policy_ids[@]})); then
		for resource in "${bootstrap_network[@]}"; do
			host="${resource%:*}"
			port="${resource##*:}"
			alternate=$((port == 65535 ? 65534 : port + 1))
			assert_denied "$host:$alternate"
		done
	fi

	# Both rule forms deny subdomains, so this probe applies to all of them.
	for resource in ${template_network[@]+"${template_network[@]}"} "${bootstrap_network[@]}"; do
		host="${resource%:*}"
		port="${resource##*:}"
		if [[ "$host" == *.* && "$host" != *:* ]]; then
			assert_denied "unexpected-subdomain.$host:$port"
		fi
	done

	for resource in 'example.invalid:443' '127.0.0.1:9' 'localhost:9' 'wildcard-policy-probe.invalid:443'; do
		assert_denied "$resource"
	done
}

inventory_global_registry_credentials() {
	local inventory=''
	inventory="$(sbx secret ls --global)" || fail 'global credential inventory unavailable'
	python3 "$contract" registry-secret-absent <<<"$inventory" ||
		fail 'global credential inventory failed its contract'
}

run_bootstrap() {
	local resource=''
	assert_effective_policy
	for resource in "${bootstrap_network[@]}"; do
		add_policy_rule "$resource"
	done
	assert_effective_policy

	sbx exec -u root -w "$staging_path" "$name" bash .sandbox/bootstrap-pi.sh system
	local -a bootstrap_args=(exec -w "$staging_path")
	[[ -z "$settings_source" ]] || bootstrap_args+=(
		-e "SANDBOX_PI_SETTINGS_SOURCE=$settings_source/settings.json"
		-e "SANDBOX_PI_EXTENSIONS_SOURCE=$extensions_source"
	)
	[[ "${SANDBOX_SKIP_BROWSER:-0}" != 1 ]] || bootstrap_args+=(-e SANDBOX_SKIP_BROWSER=1)
	sbx "${bootstrap_args[@]}" "$name" bash .sandbox/bootstrap-pi.sh user
	remove_policy_ids || fail 'bootstrap policy cleanup failed; ownership state retained'
	assert_effective_policy
}

record_created_sandbox() {
	local inventory sandbox_id
	inventory="$(sandbox_json)" || fail 'sandbox inventory unavailable after create'
	sandbox_id="$(
		python3 "$contract" sandbox-identity "$name" "$state_dir/expected-workspaces" <<<"$inventory"
	)" || fail 'created sandbox does not match the recorded creation contract'
	printf '%s\n' "$sandbox_id" >"$state_dir/sandbox-id"
}

validate_owned_attach() {
	name="$1"
	local require_complete="${2:-1}"
	state_dir="$state_root/$name"
	state_dir_is_owned || fail "refusing operation without launcher-owned state: $name"
	local file
	for file in agent template workspace-mode staging-path expected-workspaces sandbox-id; do
		[[ -f "$state_dir/$file" && ! -L "$state_dir/$file" ]] ||
			fail "launcher-owned creation contract is incomplete for $name"
	done
	if [[ "$require_complete" -eq 1 ]]; then
		[[ -f "$state_dir/creation-complete" && ! -L "$state_dir/creation-complete" ]] ||
			fail "attach creation contract is incomplete for $name"
	fi
	[[ "$(cat "$state_dir/agent")" == shell ]] || fail 'attach agent contract mismatch'
	template="$(cat "$state_dir/template")"
	[[ "$template" == "$shell_template" || "$template" == "$shell_docker_template" ]] ||
		fail 'attach template contract mismatch'
	workspace_mode="$(cat "$state_dir/workspace-mode")"
	[[ "$workspace_mode" == clone || "$workspace_mode" == direct ]] || fail 'attach workspace mode contract mismatch'
	staging_path="$(cat "$state_dir/staging-path")"
	if [[ "$workspace_mode" == clone ]]; then
		[[ "$staging_path" == "$state_dir/source-clone" && -d "$staging_path/.git" && ! -L "$staging_path/.git" ]] ||
			fail 'attach clone source contract mismatch'
	else
		[[ "$staging_path" == "$repo_root" ]] || fail 'attach direct source contract mismatch'
	fi
	sandbox_json | python3 "$contract" sandbox-identity \
		"$name" "$state_dir/expected-workspaces" "$(cat "$state_dir/sandbox-id")" >/dev/null ||
		fail 'sandbox inventory does not match launcher-owned creation contract'
}

remove_owned_sandbox() {
	name="$1"
	validate_name "$name"
	state_dir="$state_root/$name"
	state_dir_is_owned || fail "refusing to remove unowned sandbox state: $name"
	local inventory=''
	inventory="$(sandbox_json)" || fail "cannot inventory sandbox $name; ownership state retained"
	local live_present=0
	if python3 "$contract" sandbox-present "$name" <<<"$inventory"; then
		live_present=1
		validate_owned_attach "$name" 0
	fi
	policy_ids=()
	if [[ -f "$state_dir/policy-ids" ]]; then
		while IFS= read -r id; do [[ -z "$id" ]] || policy_ids+=("$id"); done <"$state_dir/policy-ids"
	fi
	local failed=0
	remove_policy_ids || failed=1
	if [[ "$failed" -eq 0 && ${#policy_ids[@]} -eq 0 && "$live_present" -eq 1 ]]; then
		sbx rm "$name" --force || failed=1
	fi
	if ! inventory="$(sandbox_json)"; then
		warn "cannot prove sandbox $name absent; ownership state retained"
		failed=1
	elif python3 "$contract" sandbox-present "$name" <<<"$inventory"; then
		warn "sandbox $name remains after removal"
		failed=1
	fi
	if [[ "$failed" -ne 0 || ${#policy_ids[@]} -ne 0 ]]; then
		fail "cleanup incomplete for $name; ownership state was retained"
	fi
	if [[ -f "$state_dir/staging-path" && "$(cat "$state_dir/workspace-mode" 2>/dev/null || true)" == clone ]]; then
		workspace_mode=clone
		staging_path="$(cat "$state_dir/staging-path")"
		remove_staging_clone || fail "failed to remove invocation-owned standalone clone: $staging_path"
	fi
	rm -rf -- "$state_dir"
	printf 'Removed invocation-owned sandbox state for %s. Upstream credential revocation, if any, is separate.\n' "$name"
}

validate_name() {
	[[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9.+-]*$ ]] || fail "invalid sandbox name: $1"
}

while (($#)); do
	case "$1" in
	--name)
		[[ $# -ge 2 ]] || fail '--name requires a value'
		name="$2"
		shift 2
		;;
	--attach)
		[[ $# -ge 2 ]] || fail '--attach requires a value'
		attach_name="$2"
		shift 2
		;;
	--remove)
		[[ $# -ge 2 ]] || fail '--remove requires a value'
		remove_name="$2"
		shift 2
		;;
	--docker)
		use_docker=1
		shift
		;;
	--direct)
		workspace_mode='direct'
		shift
		;;
	--trust-direct)
		trusted_direct=1
		shift
		;;
	--with-user-pi)
		with_user_pi=1
		shift
		;;
	--secret-service | --publish-api | --publish-web)
		fail "$1 is unsupported pending endpoint-specific live evidence"
		;;
	--detached)
		detached=1
		shift
		;;
	--no-bootstrap)
		bootstrap=0
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*) fail "unknown argument: $1" ;;
	esac
done

require_sbx_version
[[ "$state_root" == /* && "$state_root" != / ]] || fail 'state root must be an absolute non-root path'
if [[ -e "$state_root" ]]; then
	[[ -d "$state_root" && ! -L "$state_root" && -O "$state_root" ]] ||
		fail 'state root must be an owned non-symlink directory'
else
	mkdir -p "$(dirname "$state_root")"
	mkdir -m 700 "$state_root"
fi
chmod 700 "$state_root"
# Canonicalize once so recorded workspace paths use a single convention; `sbx`
# echoes back exactly what it was given, and a symlinked state root would
# otherwise record two spellings of the same directory.
state_root="$(cd "$state_root" && pwd -P)"
readonly state_root

if [[ -n "$remove_name" ]]; then
	[[ -z "$attach_name" && -z "$name" ]] || fail '--remove cannot be combined with creation or attach options'
	remove_owned_sandbox "$remove_name"
	exit 0
fi

if [[ -n "$attach_name" ]]; then
	[[ -z "$name" && "$workspace_mode" == clone && "$use_docker" -eq 0 && "$with_user_pi" -eq 0 && "$bootstrap" -eq 1 ]] ||
		fail 'attach accepts no creation-only options'
	validate_name "$attach_name"
	validate_owned_attach "$attach_name"
	if [[ "$detached" -eq 1 ]]; then
		sbx run shell --name "$attach_name" -- -lc true
	else
		sbx run shell --name "$attach_name" -- -lc 'exec pi'
	fi
	exit 0
fi

if [[ -z "$name" ]]; then
	name="pi-$(date -u +%Y%m%d%H%M%S)-$$"
fi
validate_name "$name"
inventory_global_registry_credentials
load_network_contract
sandbox_present "$name" && fail "sandbox already exists: $name"
state_dir="$state_root/$name"
[[ ! -e "$state_dir" ]] || fail "state already exists for sandbox: $name"
mkdir -m 700 "$state_dir"
printf '%s\n' "$name" >"$state_dir/.owner"
chmod 600 "$state_dir/.owner"
trap cleanup_failed_create EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

create_args=(create shell)
if [[ "$workspace_mode" == clone ]]; then
	staging_path="$state_dir/source-clone"
	expected_head="$(git -C "$repo_root" rev-parse HEAD)"
	git -c core.hooksPath=/dev/null clone --quiet --no-local --no-hardlinks --no-checkout "$repo_root" "$staging_path"
	git -C "$staging_path" -c core.hooksPath=/dev/null checkout --quiet --detach "$expected_head"
	assert_clean_tracked_source "$staging_path"
	create_args+=("$staging_path" --clone)
else
	[[ "$trusted_direct" -eq 1 ]] || fail 'direct mode requires --trust-direct after reviewing the full checkout read/write boundary'
	staging_path="$repo_root"
	printf 'WARNING: direct mode exposes the entire checkout read/write, including .git, ignored files, caches, hooks, and local credentials.\n' >&2
	create_args+=("$staging_path")
fi
printf '%s\n' "$staging_path" >"$state_dir/staging-path"

if [[ "$with_user_pi" -eq 1 ]]; then
	prepare_user_pi
	extra_workspaces=("$settings_source:ro" "$extensions_source:ro")
	create_args+=("${extra_workspaces[@]}")
	readonly extra_workspaces
fi

template="$shell_template"
[[ "$use_docker" -eq 0 ]] || template="$shell_docker_template"
create_args+=(--name "$name" --template "$template" --quiet)
printf 'shell\n' >"$state_dir/agent"
printf '%s\n' "$template" >"$state_dir/template"
printf '%s\n' "$workspace_mode" >"$state_dir/workspace-mode"
# Recorded exactly as passed to `sbx create`: extra read-only workspaces keep
# their `:ro` suffix, which `sbx ls --json` echoes back verbatim.
printf '%s\n' "$staging_path" >"$state_dir/expected-workspaces"
if ((${#extra_workspaces[@]})); then
	printf '%s\n' "${extra_workspaces[@]}" >>"$state_dir/expected-workspaces"
fi

sbx "${create_args[@]}"
record_created_sandbox
if [[ "$bootstrap" -eq 1 ]]; then
	run_bootstrap
else
	assert_effective_policy
	wire_user_pi
fi
printf 'complete\n' >"$state_dir/creation-complete"

trap - EXIT INT TERM
printf 'Sandbox %s created with template %s.\n' "$name" "$template"
if [[ "$detached" -eq 1 ]]; then
	printf 'Attach later with: .sandbox/launch-pi.sh --attach %s\n' "$name"
else
	sbx run shell --name "$name" -- -lc 'exec pi'
fi

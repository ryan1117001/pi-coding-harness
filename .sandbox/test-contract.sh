#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly repo_root
log_prefix='sandbox contract'
source "$repo_root/tools/lib/shell.sh"
load_toolchain "$repo_root/tools/toolchain.env"

readonly launcher="$repo_root/.sandbox/launch-pi.sh"
readonly fake_sbx_source="$repo_root/.sandbox/testdata/fake-sbx"
tmp_root=''

cleanup() { [[ -z "$tmp_root" ]] || rm -rf -- "$tmp_root"; }
trap cleanup EXIT INT TERM

assert_contains() { grep -Fq -- "$2" "$1" || fail "expected '$2' in $1"; }
assert_not_contains() { ! grep -Fq -- "$2" "$1" || fail "did not expect '$2' in $1"; }
expect_failure() {
	local label="$1"
	shift
	if "$@" >"$tmp_root/failure.out" 2>&1; then fail "$label unexpectedly succeeded"; fi
}

[[ -x "$launcher" ]] || fail "missing executable launcher: $launcher"
[[ -f "$fake_sbx_source" ]] || fail "missing fake sbx: $fake_sbx_source"

# Canonical from the start: the launcher canonicalizes its state root, and on
# macOS `mktemp -d` returns a /var symlink into /private/var.
tmp_root="$(cd "$(mktemp -d)" && pwd -P)"
fixture="$tmp_root/repository"
fake_bin="$tmp_root/bin"
log="$tmp_root/sbx.log"
fake_state="$tmp_root/fake-sbx"
mkdir -p "$fixture/.sandbox" "$fixture/tools/lib" "$fake_bin" "$fake_state/sandboxes" "$fake_state/policies"
cp "$launcher" "$fixture/.sandbox/launch-pi.sh"
cp "$repo_root/.sandbox/bootstrap-pi.sh" "$fixture/.sandbox/bootstrap-pi.sh"
cp "$repo_root/.sandbox/sandbox_contract.py" "$fixture/.sandbox/sandbox_contract.py"
cp "$repo_root/tools/toolchain.env" "$fixture/tools/toolchain.env"
cp "$repo_root/tools/lib/shell.sh" "$fixture/tools/lib/shell.sh"
git -C "$tmp_root" init -q -b main repository
git -C "$fixture" config user.name contract
git -C "$fixture" config user.email contract@example.invalid
printf 'fixture\n' >"$fixture/README.md"
printf '.env.secret\nauth.json\n' >"$fixture/.gitignore"
git -C "$fixture" add README.md .gitignore .sandbox tools
git -C "$fixture" -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --no-verify -m fixture
printf 'ignored-secret-sentinel\n' >"$fixture/.env.secret"
printf 'untracked-auth-sentinel\n' >"$fixture/auth.json"

install -m 755 "$fake_sbx_source" "$fake_bin/sbx"
export FAKE_SBX_LOG="$log" FAKE_SBX_STATE="$fake_state" SANDBOX_STATE_ROOT="$tmp_root/state"
export PATH="$fake_bin:$PATH"

run_fixture() { (cd "$fixture" && ./.sandbox/launch-pi.sh "$@"); }

# Leading NAME=VALUE arguments become the launcher's environment; everything
# from the first flag onwards is passed through as launcher arguments. Scoped to
# a subshell so no assignment leaks into a later case.
run_fixture_env() {
	local -a assignments=()
	while (($#)) && [[ "$1" == [A-Za-z_]*=* ]]; do
		assignments+=("$1")
		shift
	done
	(cd "$fixture" && env "${assignments[@]}" ./.sandbox/launch-pi.sh "$@")
}

# Default clone is standalone, tracked-only, and records an attachable creation contract.
run_fixture --name contract-clone --detached --no-bootstrap
assert_contains "$log" 'create shell '
assert_contains "$log" '--clone'
assert_contains "$log" '--template docker.io/docker/sandbox-templates:shell'
assert_not_contains "$log" '--direct'
clone_source="$SANDBOX_STATE_ROOT/contract-clone/source-clone"
[[ -d "$clone_source/.git" && ! -L "$clone_source/.git" ]]
[[ ! -e "$clone_source/.env.secret" && ! -e "$clone_source/auth.json" ]]
[[ -f "$SANDBOX_STATE_ROOT/contract-clone/creation-complete" ]]

# Policy inspection is always sandbox-scoped: a nameless `policy ls` cannot
# prove a scoped rule absent, so the launcher must never use that form.
assert_contains "$log" 'policy ls contract-clone --include-inactive --json'
assert_not_contains "$log" 'policy ls --include-inactive'

: >"$log"
run_fixture --attach contract-clone --detached
assert_contains "$log" 'run shell --name contract-clone'
assert_not_contains "$log" '--template'
expect_failure 'unowned attach' run_fixture --attach unknown-shell --detached
cp "$fake_state/sandboxes/contract-clone.json" "$tmp_root/record.json"
printf 'docker.io/example:bad\n' >"$SANDBOX_STATE_ROOT/contract-clone/template"
expect_failure 'template-mismatched attach' run_fixture --attach contract-clone --detached
printf 'docker.io/docker/sandbox-templates:shell\n' >"$SANDBOX_STATE_ROOT/contract-clone/template"
python3 - "$fake_state/sandboxes/contract-clone.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["workspaces"] = ["/wrong"]
open(p, "w").write(json.dumps(d))
PY
expect_failure 'workspace-mismatched attach' run_fixture --attach contract-clone --detached
cp "$tmp_root/record.json" "$fake_state/sandboxes/contract-clone.json"

# Direct mode is explicit and never invents a --direct sbx argument.
: >"$log"
run_fixture --name contract-direct --direct --trust-direct --detached --no-bootstrap
assert_contains "$log" 'create shell '
assert_not_contains "$log" '--clone'
assert_not_contains "$log" '--direct'
expect_failure 'untrusted direct mode' run_fixture --name contract-untrusted --direct --detached --no-bootstrap
for unsupported in --secret-service --publish-api --publish-web; do
	if [[ "$unsupported" == --secret-service ]]; then
		expect_failure "$unsupported" run_fixture --name "unsupported-${unsupported#--}" "$unsupported" anthropic --detached --no-bootstrap
	else
		expect_failure "$unsupported" run_fixture --name "unsupported-${unsupported#--}" "$unsupported" --detached --no-bootstrap
	fi
done
assert_not_contains "$log" 'secret set'
assert_not_contains "$log" '--publish'

# User Pi settings are byte-identical, directory-wrapped, separate, and value-safe.
# The recorded workspace contract must keep the `:ro` suffix `sbx ls` echoes back.
settings_root="$tmp_root/user-pi"
mkdir -p "$settings_root/extensions"
printf '{"packages": []}\n' >"$settings_root/settings.json"
printf 'export default {}\n' >"$settings_root/extensions/example.ts"
run_fixture_env \
	PI_USER_SETTINGS="$settings_root/settings.json" PI_USER_EXTENSIONS="$settings_root/extensions" \
	--name contract-user-pi --with-user-pi --detached --no-bootstrap
assert_contains "$log" 'settings-input:ro'
assert_contains "$log" "$settings_root/extensions:ro"
grep -Fxq "$SANDBOX_STATE_ROOT/contract-user-pi/settings-input:ro" \
	"$SANDBOX_STATE_ROOT/contract-user-pi/expected-workspaces" ||
	fail 'recorded workspace contract dropped the :ro suffix'
[[ "$(stat -f '%Lp' "$SANDBOX_STATE_ROOT/contract-user-pi/settings-input" 2>/dev/null || stat -c '%a' "$SANDBOX_STATE_ROOT/contract-user-pi/settings-input")" == 700 ]]
cmp -s "$settings_root/settings.json" "$SANDBOX_STATE_ROOT/contract-user-pi/settings-input/settings.json"
printf '{"apiKeys":{"forbidden":"must-not-print"}}\n' >"$settings_root/settings.json"
expect_failure 'legacy apiKeys' run_fixture_env \
	PI_USER_SETTINGS="$settings_root/settings.json" PI_USER_EXTENSIONS="$settings_root/extensions" \
	--name contract-api-keys --with-user-pi --detached --no-bootstrap
[[ "$(cat "$tmp_root/failure.out")" != *must-not-print* ]]
ln -s "$tmp_root" "$settings_root/settings-link.json"
expect_failure 'symlink settings' run_fixture_env \
	PI_USER_SETTINGS="$settings_root/settings-link.json" PI_USER_EXTENSIONS="$settings_root/extensions" \
	--name contract-settings-link --with-user-pi --detached --no-bootstrap

# Every prohibited tracked sentinel and tracked indirection is rejected.
test_prohibited_path() {
	local path="$1" name="$2"
	mkdir -p "$(dirname "$fixture/$path")"
	printf 'sentinel\n' >"$fixture/$path"
	git -C "$fixture" add --force "$path"
	git -C "$fixture" -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --no-verify -m "prohibit $name"
	expect_failure "tracked $path" run_fixture --name "prohibited-$name" --detached --no-bootstrap
	[[ ! -e "$SANDBOX_STATE_ROOT/prohibited-$name" ]]
	git -C "$fixture" reset -q --hard HEAD^
}
for item in '.env:env' '.npmrc:npmrc' '.pi/npm/file:pi-npm' '.pi/git/file:pi-git' 'auth.json:auth' 'node_modules/file:node-modules' '.venv/file:venv' 'private.pem:pem' 'private.key:key' 'id_rsa:rsa' 'id_ed25519:ed25519'; do
	test_prohibited_path "${item%%:*}" "${item##*:}"
done
ln -s ../outside "$fixture/escape-link"
git -C "$fixture" add escape-link
git -C "$fixture" -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --no-verify -m symlink
expect_failure 'tracked symlink escape' run_fixture --name prohibited-symlink --detached --no-bootstrap
git -C "$fixture" reset -q --hard HEAD^
head_id="$(git -C "$fixture" rev-parse HEAD)"
git -C "$fixture" update-index --add --cacheinfo "160000,$head_id,vendor/submodule"
git -C "$fixture" -c commit.gpgsign=false -c core.hooksPath=/dev/null commit -q --no-verify -m submodule
expect_failure 'tracked submodule' run_fixture --name prohibited-submodule --detached --no-bootstrap
git -C "$fixture" reset -q --hard HEAD^

# Registry inventory fails closed; unrelated global service names do not contaminate non-provider startup.
expect_failure 'global registry contamination' run_fixture_env FAKE_GLOBAL_REGISTRY=1 \
	--name registry-contaminated --detached --no-bootstrap
expect_failure 'unavailable credential inventory' run_fixture_env FAKE_SECRET_INVENTORY_FAIL=1 \
	--name registry-unknown --detached --no-bootstrap
run_fixture_env FAKE_GLOBAL_OPENAI=1 --name global-service-unrequested --detached --no-bootstrap

# Effective policy rejects every unknown exact allow. The built-in templates ship
# their own uneditable rule, which is acknowledged by default; anything else needs
# an exact opt-in.
expect_failure 'out-of-set exact policy allow' run_fixture_env FAKE_POLICY_ALLOW=evil.example:443 \
	--name policy-evil --detached --no-bootstrap
expect_failure 'unacknowledged template rule' run_fixture_env FAKE_POLICY_ALLOW=unexpected-template.example \
	--name policy-template-denied --detached --no-bootstrap
: >"$log"
run_fixture_env FAKE_POLICY_ALLOW=openrouter.ai --name policy-template-default --detached --no-bootstrap
assert_contains "$log" 'check network --sandbox policy-template-default openrouter.ai:443 --json'
: >"$log"
run_fixture_env \
	FAKE_POLICY_ALLOW=other-template.example \
	SANDBOX_EXPECTED_TEMPLATE_NETWORK=other-template.example:443 \
	--name policy-template-accepted --detached --no-bootstrap
assert_contains "$log" 'check network --sandbox policy-template-accepted other-template.example:443 --json'
assert_contains "$log" 'check network --sandbox policy-template-accepted unexpected-subdomain.other-template.example:443 --json'
assert_contains "$log" 'check network --sandbox policy-template-accepted localhost:9 --json'
assert_contains "$log" 'check network --sandbox policy-template-accepted wildcard-policy-probe.invalid:443 --json'
# A template rule is host-scoped, not port-scoped, so its alternate port must not
# be probed as denied — a live template allow covers every port on the host.
assert_not_contains "$log" 'check network --sandbox policy-template-accepted other-template.example:444 --json'

# Bootstrap mode adds exact host:port rules, probes their alternate port as
# denied, then removes every rule it recorded and re-proves the baseline.
: >"$log"
run_fixture_env \
	SANDBOX_BOOTSTRAP_NETWORK=registry.npmjs.org:443 \
	--name policy-bootstrap --detached
assert_contains "$log" 'policy allow network --sandbox policy-bootstrap registry.npmjs.org:443'
assert_contains "$log" 'check network --sandbox policy-bootstrap registry.npmjs.org:443 --json'
assert_contains "$log" 'check network --sandbox policy-bootstrap registry.npmjs.org:444 --json'
assert_contains "$log" 'policy rm network --sandbox policy-bootstrap --id '
[[ ! -s "$SANDBOX_STATE_ROOT/policy-bootstrap/policy-ids" ]] ||
	fail 'bootstrap left owned policy rules recorded'
run_fixture --remove policy-bootstrap
# A template that ships no rule of its own is still valid: acknowledged rules are
# permitted, not required.
run_fixture --name policy-template-absent --detached --no-bootstrap
expect_failure 'wildcard expected template input' run_fixture_env SANDBOX_EXPECTED_TEMPLATE_NETWORK='*.openrouter.ai:443' \
	--name policy-wildcard --detached --no-bootstrap
expect_failure 'host-only expected template input' run_fixture_env SANDBOX_EXPECTED_TEMPLATE_NETWORK='openrouter.ai' \
	--name policy-host-only --detached --no-bootstrap

# Partial create is found by unique name and removed; failures retain actionable ownership state.
expect_failure 'partial create' run_fixture_env FAKE_CREATE_PARTIAL=1 --name partial-create --detached --no-bootstrap
[[ ! -e "$fake_state/sandboxes/partial-create.json" && ! -e "$SANDBOX_STATE_ROOT/partial-create" ]]
expect_failure 'partial create cleanup failure' run_fixture_env FAKE_CREATE_PARTIAL=1 FAKE_RM_FAIL=1 \
	--name partial-retained --detached --no-bootstrap
[[ -e "$fake_state/sandboxes/partial-retained.json" && -e "$SANDBOX_STATE_ROOT/partial-retained/.owner" ]]
run_fixture --remove partial-retained

# Removal refuses same-name reuse or spec drift and can clean owned local state after proved live absence.
cp "$fake_state/sandboxes/contract-user-pi.json" "$tmp_root/user-pi-record.json"
python3 - "$fake_state/sandboxes/contract-user-pi.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["id"] = "replacement-id"
open(p, "w").write(json.dumps(d))
PY
expect_failure 'remove mismatched sandbox id' run_fixture --remove contract-user-pi
[[ -e "$SANDBOX_STATE_ROOT/contract-user-pi/.owner" && -e "$fake_state/sandboxes/contract-user-pi.json" ]]
cp "$tmp_root/user-pi-record.json" "$fake_state/sandboxes/contract-user-pi.json"
python3 - "$fake_state/sandboxes/contract-user-pi.json" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
d["workspaces"] = ["/replacement"]
open(p, "w").write(json.dumps(d))
PY
expect_failure 'remove mismatched sandbox workspace' run_fixture --remove contract-user-pi
[[ -e "$SANDBOX_STATE_ROOT/contract-user-pi/.owner" && -e "$fake_state/sandboxes/contract-user-pi.json" ]]
rm "$fake_state/sandboxes/contract-user-pi.json"
run_fixture --remove contract-user-pi
[[ ! -e "$SANDBOX_STATE_ROOT/contract-user-pi" ]]

# Policy and sandbox removal failures retain records until exact absence is proven.
printf '22222222-2222-2222-2222-222222222222 retained.example:443\n' >"$fake_state/policies/contract-clone.local"
printf '22222222-2222-2222-2222-222222222222\n' >"$SANDBOX_STATE_ROOT/contract-clone/policy-ids"
expect_failure 'policy cleanup failure' run_fixture_env FAKE_POLICY_RM_FAIL=1 --remove contract-clone
[[ -e "$SANDBOX_STATE_ROOT/contract-clone/policy-ids" && -e "$fake_state/sandboxes/contract-clone.json" ]]
run_fixture --remove contract-clone
[[ ! -e "$clone_source" && ! -e "$SANDBOX_STATE_ROOT/contract-clone" ]]
expect_failure 'sandbox removal failure' run_fixture_env FAKE_RM_FAIL=1 --remove contract-direct
[[ -e "$SANDBOX_STATE_ROOT/contract-direct/.owner" && -e "$fake_state/sandboxes/contract-direct.json" ]]
run_fixture --remove contract-direct

printf 'Sandbox synthetic contracts passed.\n'

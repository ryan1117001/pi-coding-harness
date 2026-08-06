#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly repo_root
readonly wrapper="$repo_root/.devcontainer/with-host-pi.example.sh"
readonly enabled_layer="$repo_root/.devcontainer/compose.host-pi.yml"
readonly disabled_layer_name='compose.host-pi-disabled.yml'
runtime=false
runtime_project=''
tmp_dir="$(mktemp -d)"
readonly tmp_dir
readonly fixture_dir="$tmp_dir/agent"
readonly fixture_ca="$tmp_dir/zscaler-root.pem"

fail() {
	printf 'host Pi contract test: %s\n' "$*" >&2
	exit 1
}

host_pi_binds_are_exact() {
	local compose_json="$1"
	jq -e --arg agent "$fixture_dir" \
		--arg extensions "$fixture_dir/extensions" \
		--arg settings "$fixture_dir/settings.json" '
    .services.workspace.volumes
    | all(
        if .type == "bind" and (
          ((.source // "") == $agent or ((.source // "") | startswith($agent + "/")))
          or ((.target // "") == "/home/vscode/.pi/agent" or ((.target // "") | startswith("/home/vscode/.pi/agent/")))
        ) then
          (
            .source == $extensions
            and .target == "/home/vscode/.pi/agent/extensions"
            and .read_only == true
            and .bind.create_host_path == false
          )
          or (
            .source == $settings
            and .target == "/home/vscode/.pi/agent/settings.json"
            and .read_only == true
            and .bind.create_host_path == false
          )
        else
          true
        end
      )
  ' "$compose_json" >/dev/null
}

runtime_compose_down() {
	local project="$1"
	PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" localWorkspaceFolder="$repo_root" \
		docker compose --project-name "$project" \
		-f "$repo_root/compose.yml" \
		-f "$repo_root/.devcontainer/compose.yml" \
		-f "$enabled_layer" \
		down --volumes --remove-orphans --rmi local
}

runtime_resources_are_absent() {
	local project="$1"
	[[ -z "$(docker container ls --all --quiet --filter "label=com.docker.compose.project=$project")" ]]
	[[ -z "$(docker volume ls --quiet --filter "label=com.docker.compose.project=$project")" ]]
	[[ -z "$(docker network ls --quiet --filter "label=com.docker.compose.project=$project")" ]]
	! docker image inspect "${project}-workspace:latest" >/dev/null 2>&1
}

cleanup() {
	local status=$?
	local cleanup_status=0
	trap - EXIT INT TERM
	set +e
	if [[ -n "$runtime_project" ]]; then
		runtime_compose_down "$runtime_project" >/dev/null 2>&1 || cleanup_status=1
	fi
	rm -rf "$tmp_dir"
	if [[ "$status" -eq 0 && "$cleanup_status" -ne 0 ]]; then
		status=1
	fi
	exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "${1:-}" == '--runtime' ]]; then
	runtime=true
	shift
fi
[[ "$#" -eq 0 ]] || fail "unexpected argument: $1"

mkdir -p "$fixture_dir/extensions"
printf '%s\n' 'export default function () {}' >"$fixture_dir/extensions/fixture.ts"
printf '%s\n' '{"packages":[]}' >"$fixture_dir/settings.json"
printf '%s\n' 'fixture CA certificate' >"$fixture_ca"
export NODE_EXTRA_CA_CERTS="$fixture_ca"

cd "$repo_root"

pnpm exec devcontainer read-configuration \
	--workspace-folder . \
	--include-merged-configuration >"$tmp_dir/default-configuration.json"
jq -e --arg disabled "$disabled_layer_name" \
	'.configuration.dockerComposeFile[-1] | endswith($disabled)' \
	"$tmp_dir/default-configuration.json" >/dev/null ||
	fail 'default configuration did not select the disabled host Pi layer'

PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" "$wrapper" \
	pnpm exec devcontainer read-configuration \
	--workspace-folder . \
	--include-merged-configuration >"$tmp_dir/enabled-configuration.json"
jq -e '.configuration.dockerComposeFile[-1] | endswith("compose.host-pi.yml")' \
	"$tmp_dir/enabled-configuration.json" >/dev/null ||
	fail 'wrapped configuration did not select the enabled host Pi layer'

PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" localWorkspaceFolder="$repo_root" \
	docker compose \
	-f compose.yml \
	-f .devcontainer/compose.yml \
	-f "$enabled_layer" \
	config --format json >"$tmp_dir/enabled-compose.json"
jq -e --arg source "$fixture_dir/extensions" '
  .services.workspace.volumes
  | any(
      .type == "bind"
      and .source == $source
      and .target == "/home/vscode/.pi/agent/extensions"
      and .read_only == true
      and .bind.create_host_path == false
    )
' "$tmp_dir/enabled-compose.json" >/dev/null || fail 'extensions bind is not exact and read-only'

jq -e --arg source "$fixture_dir/settings.json" '
  .services.workspace.volumes
  | any(
      .type == "bind"
      and .source == $source
      and .target == "/home/vscode/.pi/agent/settings.json"
      and .read_only == true
      and .bind.create_host_path == false
    )
' "$tmp_dir/enabled-compose.json" >/dev/null || fail 'settings bind is not exact and read-only'

jq -e --arg certificate "$fixture_ca" '
  .services.workspace.environment.NODE_EXTRA_CA_CERTS == $certificate
  and (
    .services.workspace.volumes
    | any(
        .type == "bind"
        and .source == $certificate
        and .target == $certificate
        and .read_only == true
        and .bind.create_host_path == false
      )
  )
' "$tmp_dir/enabled-compose.json" >/dev/null || fail 'CA certificate environment or bind is incorrect'

host_pi_binds_are_exact "$tmp_dir/enabled-compose.json" ||
	fail 'host Pi bind set is broader than the approved extensions and settings mounts'

jq --arg source "$fixture_dir" '
  .services.workspace.volumes += [{
    "type": "bind",
    "source": $source,
    "target": "/home/vscode/.pi/agent",
    "read_only": true,
    "bind": {"create_host_path": false}
  }]
' "$tmp_dir/enabled-compose.json" >"$tmp_dir/forbidden-agent-bind.json"
if host_pi_binds_are_exact "$tmp_dir/forbidden-agent-bind.json"; then
	fail 'bind policy accepted the complete host Pi agent directory'
fi

for target in \
	/home/vscode/.pi/agent/npm \
	/home/vscode/.pi/agent/git \
	/workspaces/workspace/.pi/npm \
	/workspaces/workspace/.pi/git; do
	jq -e --arg target "$target" '
    .services.workspace.volumes
    | any(.type == "volume" and .target == $target)
  ' "$tmp_dir/enabled-compose.json" >/dev/null || fail "missing named volume target: $target"
done

missing_dir="$tmp_dir/missing-agent"
mkdir -p "$missing_dir"
if PI_DEVCONTAINER_HOST_PI_DIR="$missing_dir" "$wrapper" true >"$tmp_dir/missing.out" 2>&1; then
	fail 'wrapper accepted missing host Pi paths'
fi
[[ ! -e "$missing_dir/extensions" && ! -e "$missing_dir/settings.json" ]] ||
	fail 'wrapper created a missing host Pi path'

chmod 400 "$fixture_dir/extensions"
if PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" "$wrapper" true >"$tmp_dir/non-searchable.out" 2>&1; then
	fail 'wrapper accepted a non-searchable extensions directory'
fi
chmod 700 "$fixture_dir/extensions"

readonly secret_marker='DO_NOT_PRINT_SECRET_MARKER'
printf '%s\n' "{\"apiKeys\":{\"fixture\":\"$secret_marker\"},\"packages\":[]}" \
	>"$fixture_dir/settings.json"
if PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" "$wrapper" true >"$tmp_dir/api-keys.out" 2>&1; then
	fail 'wrapper accepted legacy apiKeys settings'
fi
grep -Fq 'apiKeys' "$tmp_dir/api-keys.out" || fail 'apiKeys rejection was not actionable'
if grep -Fq "$secret_marker" "$tmp_dir/api-keys.out"; then
	fail 'apiKeys rejection printed a credential value'
fi

printf '%s\n' "{\"api\\u004beys\":{\"fixture\":\"$secret_marker\"},\"packages\":[]}" \
	>"$fixture_dir/settings.json"
if PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" "$wrapper" true >"$tmp_dir/escaped-key.out" 2>&1; then
	fail 'wrapper accepted an escaped top-level settings key'
fi
if grep -Fq "$secret_marker" "$tmp_dir/escaped-key.out"; then
	fail 'escaped-key rejection printed a credential value'
fi
printf '%s\n' '{"packages":[]}' >"$fixture_dir/settings.json"

if [[ "$runtime" == true ]]; then
	runtime_project="workspace-host-pi-test-$$"
	PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" localWorkspaceFolder="$repo_root" \
		docker compose --project-name "$runtime_project" \
		-f compose.yml \
		-f .devcontainer/compose.yml \
		-f "$enabled_layer" \
		up --detach --no-deps workspace >/dev/null

	container_id="$(
		PI_DEVCONTAINER_HOST_PI_DIR="$fixture_dir" localWorkspaceFolder="$repo_root" \
			docker compose --project-name "$runtime_project" \
			-f compose.yml \
			-f .devcontainer/compose.yml \
			-f "$enabled_layer" \
			ps --quiet workspace
	)"
	[[ -n "$container_id" ]] || fail 'runtime workspace container was not created'
	docker inspect "$container_id" >"$tmp_dir/runtime-inspect.json"

	for pair in \
		"$fixture_dir/extensions:/home/vscode/.pi/agent/extensions" \
		"$fixture_dir/settings.json:/home/vscode/.pi/agent/settings.json" \
		"$fixture_ca:$fixture_ca"; do
		source_path="${pair%%:*}"
		target_path="${pair#*:}"
		jq -e --arg source "$source_path" --arg target "$target_path" '
      .[0].Mounts
      | any(.Type == "bind" and .Source == $source and .Destination == $target and .RW == false)
    ' "$tmp_dir/runtime-inspect.json" >/dev/null || fail "runtime bind mismatch: $target_path"
	done

	jq -e '
    .[0].Mounts
    | all(.Destination != "/home/vscode/.pi/agent/auth.json")
  ' "$tmp_dir/runtime-inspect.json" >/dev/null || fail 'runtime unexpectedly mounted auth.json'

	runtime_compose_down "$runtime_project" >/dev/null
	runtime_resources_are_absent "$runtime_project" || fail 'runtime fixture resources were not fully removed'
	runtime_project=''
fi

printf 'Host Pi Dev Container contract passed%s.\n' "$([[ "$runtime" == true ]] && printf ' with runtime mounts')"

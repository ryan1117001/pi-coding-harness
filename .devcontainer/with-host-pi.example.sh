#!/usr/bin/env bash
set -Eeuo pipefail

fail() {
	printf 'host Pi integration: %s\n' "$*" >&2
	exit 1
}

has_forbidden_settings_key() {
	local candidate_file="$1"
	awk '
    BEGIN {
      object_depth = 0
      array_depth = 0
      in_string = 0
      escaped = 0
      capture = 0
      awaiting_colon = 0
    }
    {
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)

        if (in_string) {
          if (escaped) {
            if (capture) {
              token = token "\\" c
              token_escaped = 1
            }
            escaped = 0
          } else if (c == "\\") {
            escaped = 1
          } else if (c == "\"") {
            in_string = 0
            if (capture) {
              candidate = token
              candidate_escaped = token_escaped
              awaiting_colon = 1
            }
          } else if (capture) {
            token = token c
          }
          continue
        }

        if (awaiting_colon) {
          if (c ~ /[[:space:]]/) {
            continue
          }
          if (c == ":") {
            if (candidate_escaped) {
              exit 12
            }
            if (candidate == "apiKeys") {
              exit 10
            }
          }
          awaiting_colon = 0
        }

        if (c == "\"") {
          in_string = 1
          capture = object_depth == 1 && array_depth == 0
          token = ""
          token_escaped = 0
        } else if (c == "{") {
          object_depth++
        } else if (c == "}") {
          object_depth--
        } else if (c == "[") {
          array_depth++
        } else if (c == "]") {
          array_depth--
        }
      }
    }
  ' "$candidate_file"
}

[[ "$#" -gt 0 ]] || fail 'provide a command to execute'
readonly host_agent_input="${PI_DEVCONTAINER_HOST_PI_DIR:-${HOME:?HOME is required}/.pi/agent}"
[[ -d "$host_agent_input" ]] || fail 'host Pi agent directory does not exist'
host_agent_dir="$(cd "$host_agent_input" && pwd -P)"
readonly host_agent_dir
readonly extensions_dir="$host_agent_dir/extensions"
readonly settings_file="$host_agent_dir/settings.json"
readonly host_ca_input="${NODE_EXTRA_CA_CERTS:-}"
[[ -f "$host_ca_input" && ! -L "$host_ca_input" && -r "$host_ca_input" ]] ||
	fail 'NODE_EXTRA_CA_CERTS must name a readable, non-symlink regular file'
host_ca_file="$(cd "$(dirname "$host_ca_input")" && pwd -P)/$(basename "$host_ca_input")"
readonly host_ca_file

[[ -d "$extensions_dir" && ! -L "$extensions_dir" && -r "$extensions_dir" && -x "$extensions_dir" ]] ||
	fail 'host Pi extensions must be a readable, searchable, non-symlink directory'
[[ -f "$settings_file" && ! -L "$settings_file" && -r "$settings_file" ]] ||
	fail 'host Pi settings.json must be a readable, non-symlink regular file'

set +e
has_forbidden_settings_key "$settings_file"
settings_status=$?
set -e
case "$settings_status" in
0) ;;
10) fail 'host Pi settings.json contains forbidden top-level apiKeys' ;;
12) fail 'host Pi settings.json contains an escaped top-level key that cannot be safely validated' ;;
*) fail 'host Pi settings.json could not be structurally validated' ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly script_dir
export PI_DEVCONTAINER_HOST_PI_DIR="$host_agent_dir"
export NODE_EXTRA_CA_CERTS="$host_ca_file"
export PI_DEVCONTAINER_HOST_PI_COMPOSE="$script_dir/compose.host-pi.yml"
exec "$@"

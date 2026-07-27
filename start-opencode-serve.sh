#!/bin/sh
set -eu

PORT="${OPENCODE_PORT:-9002}"
HOSTNAME="${OPENCODE_HOSTNAME:-0.0.0.0}"
CONFIG_FILE="${OPENCODE_CONFIG_FILE:-/home/opencode/.config/opencode/opencode.json}"
CONFIG_TEMPLATE="${OPENCODE_CONFIG_TEMPLATE:-compatible}"

json_string() {
  printf '%s' "$1" | awk '
    BEGIN { printf "\"" }
    {
      gsub(/\\/, "\\\\")
      gsub(/"/, "\\\"")
      gsub(/\t/, "\\t")
      gsub(/\r/, "\\r")
      if (NR > 1) {
        printf "\\n"
      }
      printf "%s", $0
    }
    END { printf "\"" }
  '
}

write_openai_compatible_config() {
  provider_id="${OPENCODE_PROVIDER_ID:-myprovider}"
  provider_npm="${OPENCODE_PROVIDER_NPM:-@ai-sdk/openai-compatible}"
  provider_name="${OPENCODE_PROVIDER_NAME:-$provider_id}"
  provider_base_url="${OPENCODE_PROVIDER_BASE_URL:-https://api.myprovider.com/v1}"
  provider_api_key="${OPENCODE_PROVIDER_API_KEY:-}"
  provider_authorization="${OPENCODE_PROVIDER_AUTHORIZATION:-}"
  model_id="${OPENCODE_MODEL_ID:-my-model-name}"
  model_name="${OPENCODE_MODEL_NAME:-$model_id}"
  model_context="${OPENCODE_MODEL_CONTEXT:-}"
  model_output="${OPENCODE_MODEL_OUTPUT:-}"

  case "$model_context" in
    *[!0-9]*) echo "OPENCODE_MODEL_CONTEXT must be a positive integer" >&2; exit 1 ;;
  esac

  case "$model_output" in
    *[!0-9]*) echo "OPENCODE_MODEL_OUTPUT must be a positive integer" >&2; exit 1 ;;
  esac

  mkdir -p "$(dirname "$CONFIG_FILE")"
  {
    printf '{\n'
    printf '  "$schema": "https://opencode.ai/config.json",\n'
    printf '  "provider": {\n'
    printf '    %s: {\n' "$(json_string "$provider_id")"
    printf '      "npm": %s,\n' "$(json_string "$provider_npm")"
    printf '      "name": %s,\n' "$(json_string "$provider_name")"
    printf '      "options": {\n'
    printf '        "baseURL": %s,\n' "$(json_string "$provider_base_url")"
    printf '        "apiKey": %s' "$(json_string "$provider_api_key")"
    if [ -n "$provider_authorization" ]; then
      printf ',\n'
      printf '        "headers": {\n'
      printf '          "Authorization": %s\n' "$(json_string "$provider_authorization")"
      printf '        }\n'
    else
      printf '\n'
    fi
    printf '      },\n'
    printf '      "models": {\n'
    printf '        %s: {\n' "$(json_string "$model_id")"
    printf '          "name": %s' "$(json_string "$model_name")"
    if [ -n "$model_context" ] || [ -n "$model_output" ]; then
      printf ',\n'
      printf '          "limit": {\n'
      if [ -n "$model_context" ]; then
        printf '            "context": %s' "$model_context"
        if [ -n "$model_output" ]; then
          printf ','
        fi
        printf '\n'
      fi
      if [ -n "$model_output" ]; then
        printf '            "output": %s\n' "$model_output"
      fi
      printf '          }\n'
    else
      printf '\n'
    fi
    printf '        }\n'
    printf '      }\n'
    printf '    }\n'
    printf '  }\n'
    printf '}\n'
  } > "$CONFIG_FILE"
}

if [ "$CONFIG_TEMPLATE" = "compatible" ] || [ "$CONFIG_TEMPLATE" = "openai-compatible" ]; then
  write_openai_compatible_config
fi

set -- serve --port "$PORT" --hostname "$HOSTNAME"

if [ -n "${OPENCODE_MDNS:-}" ]; then
  set -- "$@" --mdns
fi

if [ -n "${OPENCODE_MDNS_DOMAIN:-}" ]; then
  set -- "$@" --mdns-domain "$OPENCODE_MDNS_DOMAIN"
fi

if [ -n "${OPENCODE_CORS:-}" ]; then
  old_ifs=$IFS
  IFS=','
  for origin in $OPENCODE_CORS; do
    trimmed=$(printf '%s' "$origin" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$trimmed" ]; then
      set -- "$@" --cors "$trimmed"
    fi
  done
  IFS=$old_ifs
fi

exec opencode "$@"

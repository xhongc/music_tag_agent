#!/bin/sh
set -eu

PORT="${OPENCODE_PORT:-9002}"
HOSTNAME="${OPENCODE_HOSTNAME:-0.0.0.0}"

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

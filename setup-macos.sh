#!/bin/bash
set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
    printf '%s\n' 'This setup script is for macOS only.' >&2
    exit 1
fi
if [[ "$EUID" -eq 0 ]]; then
    printf '%s\n' 'Run without sudo. Shared hosts and trust setup belongs to caddy-local.' >&2
    exit 1
fi
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker info >/dev/null
docker compose version >/dev/null
if ! docker network inspect local-apps >/dev/null 2>&1; then
    printf '%s\n' 'Initialize the sibling caddy-local stack first to create local-apps.' >&2
    exit 1
fi
bash "$script_dir/initialize.sh"
docker compose -f "$script_dir/compose.yaml" up -d
printf '%s\n' 'SearXNG started. With caddy-local running, open https://searxng.test.'

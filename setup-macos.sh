#!/bin/bash
set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
    printf '%s\n' 'This setup script is for macOS only.' >&2
    exit 1
fi
if [[ "$EUID" -eq 0 ]]; then
    printf '%s\n' 'Run without sudo; only the hosts step will request administrator access.' >&2
    exit 1
fi
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v docker >/dev/null || { printf '%s\n' 'Install Docker Desktop first.' >&2; exit 1; }
docker info >/dev/null
docker compose version >/dev/null
bash "$script_dir/initialize.sh"
sudo /bin/bash "$script_dir/set-local-host.sh"
docker compose -f "$script_dir/compose.yaml" up -d
bash "$script_dir/trust-local-ca.sh"
printf '%s\n' 'Setup complete: https://searxng.test'

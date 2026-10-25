#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
settings_path="$script_dir/config/settings.yml"
if [[ -e "$settings_path" ]]; then
    printf '%s\n' 'Existing config/settings.yml preserved.'
    exit 0
fi
command -v openssl >/dev/null
umask 077
mkdir -p "$script_dir/config"
secret="$(openssl rand -hex 32)"
temporary_settings="$(mktemp "$script_dir/config/.settings.XXXXXX")"
trap 'rm -f "$temporary_settings"' EXIT
sed "s/REPLACE_WITH_RANDOM_SECRET/$secret/" "$script_dir/settings.yml.example" > "$temporary_settings"
mv "$temporary_settings" "$settings_path"
printf '%s\n' 'Created config/settings.yml with a random instance secret.'

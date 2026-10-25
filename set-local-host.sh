#!/bin/bash
set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
    printf '%s\n' 'This hosts setup script is for macOS only.' >&2
    exit 1
fi
if [[ "$EUID" -ne 0 ]]; then
    printf '%s\n' 'Run this script with sudo to update /etc/hosts.' >&2
    exit 1
fi
# Check all aliases, ignoring comments and case. Reject conflicting entries.
mapping_state="$(awk '
    { sub(/#.*/, "") }
    { for (i = 2; i <= NF; i++) {
        if (tolower($i) == "searxng.test") {
            found = 1
            if ($1 != "127.0.0.1") conflict = 1
        }
    } }
    END { if (conflict) print "conflict"; else if (found) print "present"; else print "absent" }
' /etc/hosts)"
case "$mapping_state" in
    conflict)
        printf '%s\n' 'An existing searxng.test entry needs manual review; /etc/hosts was not changed.' >&2
        exit 1
        ;;
    absent)
        backup_path="$(mktemp /etc/hosts.searxng-backup.XXXXXX)"
        cp -p /etc/hosts "$backup_path"
        printf '\n127.0.0.1 searxng.test # SearXNG local test\n' >> /etc/hosts
        printf 'Saved hosts backup: %s\n' "$backup_path"
        ;;
    present) printf '%s\n' 'The localhost hosts entry already exists.' ;;
esac
/usr/bin/dscacheutil -flushcache
/usr/bin/killall -HUP mDNSResponder
printf '%s\n' 'searxng.test now maps to 127.0.0.1.'

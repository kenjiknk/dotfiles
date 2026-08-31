#!/usr/bin/env bash
# Waybar custom module: days since the last full system upgrade (pacman).
# Emits JSON: text = day count, tooltip = date, class = warning/critical.

set -euo pipefail

LOG=/var/log/pacman.log
WARN_DAYS=7
CRIT_DAYS=14

json() { printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$1" "$2" "$3"; }

if [[ ! -r $LOG ]]; then
    json "?" "pacman.log not readable" ""
    exit 0
fi

# Last "starting full system upgrade" entry, e.g. [2026-08-30T15:59:55-0300]
stamp=$(grep -F 'starting full system upgrade' "$LOG" | tail -n 1 | sed -n 's/^\[\([^]]*\)\].*/\1/p')

if [[ -z $stamp ]]; then
    json "?" "no full system upgrade recorded" ""
    exit 0
fi

if ! then=$(date -d "$stamp" +%s 2>/dev/null); then
    json "?" "unparsable timestamp: $stamp" ""
    exit 0
fi

days=$(( ($(date +%s) - then) / 86400 ))
(( days < 0 )) && days=0

class=""
(( days >= WARN_DAYS )) && class="warning"
(( days >= CRIT_DAYS )) && class="critical"

json "$days" "Last upgrade: $(date -d "$stamp" '+%Y-%m-%d %H:%M')" "$class"

#!/bin/bash

set -uo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local desc="$1" condition="$2"
    if eval "$condition" &>/dev/null; then
        ((PASS++))
        printf '%b\n' "  ${GREEN}pass${NC} $desc"
    else
        ((FAIL++))
        printf '%b\n' "  ${RED}fail${NC} $desc"
    fi
}

section() { printf '%b\n' "\n${BOLD}$1${NC}"; }

check_home_absent() {
    local desc="$1" pkg="$2" bin="$3" rel="$4"
    if pacman -Q "$pkg" &>/dev/null; then
        return 0
    fi
    if command -v "$bin" &>/dev/null; then
        return 0
    fi
    local u_home=""
    for u_home in /home/*; do
        [[ -d "$u_home" ]] || continue
        if [[ -e "$u_home/$rel" ]]; then
            return 1
        fi
    done
    return 0
}

section "System Hygiene"
if command -v pacman &>/dev/null; then
    check "no orphan packages" "[[ -z \"\$(pacman -Qtdq 2>/dev/null)\" ]]"
fi
if command -v journalctl &>/dev/null; then
    check "journal size under 500M" "[[ \"\$(journalctl --disk-usage 2>/dev/null | grep -oE '[0-9.]+M' | head -1 | tr -d 'M' | cut -d. -f1)\" -lt 500 ]]"
fi
check "no stale coredumps older than 14 days" "[[ -z \"\$(find /var/lib/systemd/coredump -mindepth 1 -mtime +14 2>/dev/null)\" ]]"

section "Debloated Home Leftovers"
check "chromium config absent when chromium removed" "check_home_absent 'chromium' chromium chromium .config/chromium"
check "nautilus data absent when nautilus removed" "check_home_absent 'nautilus' nautilus nautilus .config/nautilus"
check "totem config absent when totem removed" "check_home_absent 'totem' totem totem .config/totem"
check "evince data absent when evince removed" "check_home_absent 'evince' evince evince .config/evince"
check "dolphin config absent when dolphin removed" "check_home_absent 'dolphin' dolphin dolphin .config/dolphinrc"
check "okular config absent when okular removed" "check_home_absent 'okular' okular okular .config/okularrc"
check "gwenview config absent when gwenview removed" "check_home_absent 'gwenview' gwenview gwenview .config/gwenviewrc"
check "obsidian config absent when obsidian removed" "check_home_absent 'obsidian' obsidian obsidian .config/obsidian"

section "Stale Launchers and Caches"
check "no omarchy webapp launchers in homes" "[[ -z \"\$(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' /home/*/.local/share/applications 2>/dev/null)\" ]]"
check "no thumbnails older than 30 days" "[[ -z \"\$(find /home/*/.cache/thumbnails -mindepth 1 -atime +30 2>/dev/null)\" ]]"
check "no trash older than 30 days" "[[ -z \"\$(find /home/*/.local/share/Trash/files -mindepth 1 -atime +30 2>/dev/null)\" ]]"

section "Pipeline integrity"
check "no unverified AUR" "! grep -q 'aur_install ' '$SCRIPT_DIR/setup.sh'"
check "no yay fallback"   "! grep -q 'yay -S' '$SCRIPT_DIR/setup.sh'"

printf '\n'
printf '%b\n' "${BOLD}Passed: $PASS  Failed: $FAIL${NC}"
[[ $FAIL -eq 0 ]] || exit 1

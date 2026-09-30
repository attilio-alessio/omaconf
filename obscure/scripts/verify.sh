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

check_user_gate() {
    local u_home="$1"
    [[ -d "$u_home/.config/yazi/plugins/obscure.yazi" ]] || return 1
    [[ -f "$u_home/.config/yazi/plugins/obscure.yazi/main.lua" ]] || return 1
    [[ -f "$u_home/.config/obscure/patterns" ]] || return 1
    grep -qF "omaconf obscure" "$u_home/.config/yazi/yazi.toml" 2>/dev/null || return 1
    grep -qF 'run = "obscure"' "$u_home/.config/yazi/yazi.toml" 2>/dev/null || return 1
    grep -qF 'use = "obscure-view"' "$u_home/.config/yazi/yazi.toml" 2>/dev/null || return 1
    grep -qF "omaconf obscure" "$u_home/.config/yazi/theme.toml" 2>/dev/null || return 1
    return 0
}

check_user_idle() {
    local u_home="$1"
    [[ ! -f "$u_home/.local/state/omarchy/indicators/stay-awake" ]] || return 1
    [[ ! -f "$u_home/.local/state/omarchy/toggles/screensaver-off" ]] || return 1
    return 0
}

section "Helpers"
check "obscure-view installed" "[[ -x /usr/local/bin/obscure-view ]]"

section "Yazi Gate"
_gated=0
_total=0
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    _total=$((_total + 1))
    if check_user_gate "$u_home"; then
        _gated=$((_gated + 1))
    fi
done
check "yazi gate installed for all users ($_gated/$_total)" "[[ $_total -gt 0 && $_gated -eq $_total ]]"

section "Idle Obscure"
_idle=0
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    if check_user_idle "$u_home"; then
        _idle=$((_idle + 1))
    fi
done
check "idle lock allowed for all users ($_idle/$_total)" "[[ $_total -gt 0 && $_idle -eq $_total ]]"

section "Pipeline integrity"
check "no unverified AUR" "! grep -q 'aur_install ' '$SCRIPT_DIR/setup.sh'"
check "no yay fallback"   "! grep -q 'yay -S' '$SCRIPT_DIR/setup.sh'"

printf '\n'
printf '%b\n' "${BOLD}Passed: $PASS  Failed: $FAIL${NC}"
[[ $FAIL -eq 0 ]] || exit 1

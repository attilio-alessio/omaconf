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

section "Battery Charge Threshold"
check "power.conf policy exists" "[[ -f /etc/omaconf/power.conf ]]"
check "power.conf defines charge limit" "grep -q 'BATTERY_CHARGE_LIMIT=75' /etc/omaconf/power.conf 2>/dev/null"
check "battery charge udev rule exists" "[[ -f /etc/udev/rules.d/98-battery-charge-threshold.rules ]]"
check "battery charge tmpfiles exists" "[[ -f /etc/tmpfiles.d/battery-charge-threshold.conf ]]"
check "battery service enabled" "systemctl is-enabled battery-charge-threshold.service &>/dev/null || [[ -L /etc/systemd/system/multi-user.target.wants/battery-charge-threshold.service ]]"
if ls /sys/class/power_supply/BAT*/charge_control_end_threshold &>/dev/null; then
    check "live battery limit is 75%" "grep -qx '75' /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null"
fi

section "Low-Battery Session Protection"
check "low-battery hibernate policy exists" "[[ -f /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf ]]"
check "low-battery action is hibernate" "grep -q '^CriticalPowerAction=Hibernate' /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf 2>/dev/null"
check "low-battery warning at 20 percent" "grep -q '^PercentageLow=20' /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf 2>/dev/null"
check "low-battery critical at 10 percent" "grep -q '^PercentageCritical=10' /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf 2>/dev/null"
check "hibernate action at 5 percent" "grep -q '^PercentageAction=5' /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf 2>/dev/null"

section "Runtime Performance"
check "perf sysctl persisted" "[[ -f /etc/sysctl.d/99-perf.conf ]]"
check "NMI watchdog disabled live" "[[ \"\$(cat /proc/sys/kernel/nmi_watchdog 2>/dev/null)\" == 0 ]]"
check "fstrim timer enabled" "systemctl is-enabled fstrim.timer &>/dev/null"

section "AUR integrity"
check "no unverified AUR" "! grep -q 'aur_install ' '$SCRIPT_DIR/setup.sh'"
check "no yay fallback"   "! grep -q 'yay -S' '$SCRIPT_DIR/setup.sh'"

printf '\n'
printf '%b\n' "${BOLD}Passed: $PASS  Failed: $FAIL${NC}"
[[ $FAIL -eq 0 ]] || exit 1

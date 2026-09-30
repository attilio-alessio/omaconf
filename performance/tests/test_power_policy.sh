#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$PROJECT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Hardware & Battery Power Management Policy"

POWER_MODULE="$PROJECT_ROOT/scripts/modules/89-battery-charge.sh"
UPower_MODULE="$PROJECT_DIR/scripts/modules/10-power.sh"
assert_file_exists "power module exists" "$POWER_MODULE"
assert_file_contains "power module provisions /etc/omaconf/power.conf" "$POWER_MODULE" "/etc/omaconf/power.conf"
assert_file_contains "power module sets 75% battery limit policy" "$POWER_MODULE" "BATTERY_CHARGE_LIMIT=75"
assert_file_contains "power module provisions udev battery rule" "$POWER_MODULE" "98-battery-charge-threshold.rules"
assert_file_contains "power module provisions systemd-tmpfiles rule" "$POWER_MODULE" "battery-charge-threshold.conf"
assert_file_contains "power module provisions systemd battery service" "$POWER_MODULE" "battery-charge-threshold.service"
assert_file_contains "power module provisions UPower low-battery policy" "$UPower_MODULE" "99-omaconf-low-battery.conf"
assert_file_contains "power module hibernates at critical battery level" "$UPower_MODULE" "CriticalPowerAction=Hibernate"
assert_file_contains "power module warns at 20 percent battery" "$UPower_MODULE" "PercentageLow=20"

if [[ -f /etc/omaconf/power.conf ]]; then
    assert_file_contains "power.conf defines BATTERY_CHARGE_LIMIT" "/etc/omaconf/power.conf" "BATTERY_CHARGE_LIMIT=[0-9]+"
fi

if [[ -f /etc/udev/rules.d/98-battery-charge-threshold.rules ]]; then
    assert_file_contains "udev rule matches power_supply subsystem" "/etc/udev/rules.d/98-battery-charge-threshold.rules" "SUBSYSTEM==\"power_supply\""
    assert_file_contains "udev rule targets battery kernel devices" "/etc/udev/rules.d/98-battery-charge-threshold.rules" "KERNEL==\"BAT\*\|BATT\*\""
    assert_file_contains "udev rule configures charge limit" "/etc/udev/rules.d/98-battery-charge-threshold.rules" "ATTR\{charge_control_end_threshold\}="
fi

if [[ -f /etc/tmpfiles.d/battery-charge-threshold.conf ]]; then
    assert_file_contains "tmpfiles uses safe write prefix" "/etc/tmpfiles.d/battery-charge-threshold.conf" "^w- /sys/class/power_supply/\*/charge_control_end_threshold"
fi

if [[ -f /etc/systemd/system/battery-charge-threshold.service ]]; then
    assert_file_contains "battery service applies shared helper" "/etc/systemd/system/battery-charge-threshold.service" "omaconf-set-battery-charge-limit"
    assert_true "battery charge threshold service is enabled" "systemctl is-enabled battery-charge-threshold.service &>/dev/null || [[ -L /etc/systemd/system/multi-user.target.wants/battery-charge-threshold.service ]]"
fi

if [[ -f /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf ]]; then
    assert_file_contains "UPower drop-in hibernates at critical level" "/etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf" "CriticalPowerAction=Hibernate"
    assert_file_contains "UPower drop-in acts at 5 percent" "/etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf" "PercentageAction=5"
fi

check_live_battery_threshold() {
    local checked=0
    for bat_node in /sys/class/power_supply/BAT*/charge_control_end_threshold /sys/class/power_supply/BAT*/charge_stop_threshold /sys/class/power_supply/BATT*/charge_control_end_threshold; do
        if [[ -f "$bat_node" ]]; then
            checked=$((checked + 1))
            local val
            val=$(cat "$bat_node" 2>/dev/null)
            [[ "$val" == "75" ]] || return 1
        fi
    done
    return 0
}

if ls /sys/class/power_supply/BAT*/charge_control_end_threshold &>/dev/null && [[ -f /etc/omaconf/power.conf ]]; then
    assert_true "live battery charge threshold matches policy (75%)" "check_live_battery_threshold"
fi

test_summary

#!/bin/bash
set -euo pipefail

limit=75
config=/etc/omaconf/power.conf
if [[ -r "$config" ]]; then
    configured_limit=$(sed -n 's/^BATTERY_CHARGE_LIMIT=\([0-9][0-9]*\)$/\1/p' "$config" | head -n 1)
    [[ "$configured_limit" =~ ^([5-9][0-9]|100)$ ]] && limit="$configured_limit"
fi

for battery in /sys/class/power_supply/BAT* /sys/class/power_supply/BATT*; do
    [[ -d "$battery" ]] || continue
    for attribute in charge_control_end_threshold charge_stop_threshold charge_end_threshold; do
        node="$battery/$attribute"
        [[ -w "$node" ]] || continue
        printf '%s\n' "$limit" > "$node" 2>/dev/null || continue
        break
    done
done

#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Lockscreen Regression & Input Safety"

count_active_lockers() {
    local running=0
    for locker in hyprlock swaylock gtklock i3lock waylock; do
        if pgrep -x "$locker" &>/dev/null; then
            running=$((running + 1))
        fi
    done
    [[ $running -le 1 ]]
}

assert_true "No concurrent duplicate screen lockers running" "count_active_lockers"

if [[ -f /etc/usbguard/rules.conf ]]; then
    assert_true "USBGuard allows HID input devices (prevents frozen lockscreen)" \
        "grep -qE '(03:00:01|03:01:01|03:01:02|interface-class == \{ 03:..:.. \}|allow)' /etc/usbguard/rules.conf 2>/dev/null"
fi

assert_true "Primary user belongs to wheel group" "[[ \$(id -u) -eq 0 ]] || groups | grep -qw 'wheel' || id -Gn | grep -qw 'wheel'"
assert_true "User shell is defined in /etc/shells" "grep -qFx \"${SHELL:-/bin/bash}\" /etc/shells"

for pam_file in /etc/pam.d/system-auth /etc/pam.d/hyprlock /etc/pam.d/swaylock /etc/pam.d/gtklock; do
    if [[ -f "$pam_file" ]]; then
        assert_false "PAM file $pam_file has no broken syntax" "grep -qE '^[[:space:]]*[^#[:space:]]+[[:space:]]+$' '$pam_file'"
    fi
done

assert_false "No duplicate swayidle lock commands in active environment" \
    "pgrep -fa swayidle 2>/dev/null | grep -E 'hyprlock.*swaylock|swaylock.*hyprlock' | grep -v grep"

test_summary

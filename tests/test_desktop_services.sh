#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Desktop Services & Session Health"

assert_warn "D-Bus session bus accessible" "[[ -n \"${DBUS_SESSION_BUS_ADDRESS:-}\" ]] || busctl --user status &>/dev/null"
assert_warn "XDG runtime directory exists and is valid" "[[ -d \"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}\" ]]"
assert_warn "Polkit daemon enabled or active" "systemctl is-active polkit.service &>/dev/null || systemctl is-enabled polkit.service &>/dev/null || pacman -Q polkit &>/dev/null"
assert_warn "Audio server active (PipeWire)" "systemctl --user is-active pipewire.service &>/dev/null || pgrep -x pipewire &>/dev/null"
assert_warn "WirePlumber session manager active" "systemctl --user is-active wireplumber.service &>/dev/null || pgrep -x wireplumber &>/dev/null"

if [[ -f /etc/security/access.conf ]] && grep -qE '^\+:root:' /etc/security/access.conf 2>/dev/null; then
    assert_file_contains "access.conf permits wheel" "/etc/security/access.conf" "\+:wheel:LOCAL"
    assert_file_contains "access.conf permits gdm" "/etc/security/access.conf" "\+:gdm:LOCAL"
    assert_file_contains "access.conf permits sddm" "/etc/security/access.conf" "\+:sddm:LOCAL"
    assert_file_contains "access.conf permits greetd" "/etc/security/access.conf" "\+:greetd:LOCAL"
    assert_file_contains "access.conf permits lightdm" "/etc/security/access.conf" "\+:lightdm:LOCAL"
fi

assert_false "avahi-daemon disabled" "systemctl is-enabled avahi-daemon.service 2>/dev/null | grep -q '^enabled$'"
assert_false "cups disabled" "systemctl is-enabled cups.service 2>/dev/null | grep -q '^enabled$'"

test_summary

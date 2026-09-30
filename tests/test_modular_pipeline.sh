#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$PROJECT_DIR/scripts/modules"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Modular Pipeline Architecture & Integrity"

EXPECTED_MODULES=(
    "00-env.sh"
    "05-locale.sh"
    "10-debloat.sh"
    "20-defaults.sh"
    "30-theming.sh"
    "32-omaqt.sh"
    "33-nvim.sh"
    "35-shell-plugins.sh"
    "40-firewall.sh"
    "50-kernel.sh"
    "60-auth.sh"
    "70-ssh.sh"
    "80-services.sh"
    "85-security-stack.sh"
    "89-battery-charge.sh"
    "90-hardware-power.sh"
    "95-maintenance.sh"
)

for m in "${EXPECTED_MODULES[@]}"; do
    mpath="$MODULES_DIR/$m"
    assert_file_exists "module $m exists" "$mpath"
    assert_file_executable "module $m is executable" "$mpath"
    assert_file_contains "module $m has strict mode" "$mpath" "set -euo pipefail"
    assert_file_contains "setup.sh references module $m" "$PROJECT_DIR/scripts/setup.sh" "$m"
done

assert_file_contains "00-env defines aur_verified_install" "$MODULES_DIR/00-env.sh" "aur_verified_install\(\)"
assert_file_contains "00-env defines omarchy_as helper" "$MODULES_DIR/00-env.sh" "omarchy_as\(\)"
assert_file_contains "omarchy_as forwards the user session bus" "$MODULES_DIR/00-env.sh" "DBUS_SESSION_BUS_ADDRESS"
assert_file_contains "20-defaults routes the browser through omarchy_as" "$MODULES_DIR/20-defaults.sh" "omarchy_as"
assert_file_contains "35-shell-plugins uses the canonical omamp source" "$MODULES_DIR/35-shell-plugins.sh" "omablot/omamp.git"
assert_file_contains "35-shell-plugins routes through omarchy_as" "$MODULES_DIR/35-shell-plugins.sh" "omarchy_as"
assert_file_contains "32-omaqt tracks the omaqt checkout" "$MODULES_DIR/32-omaqt.sh" "OMAQT_DIR"
assert_file_contains "33-nvim provisions the root nvimconf" "$MODULES_DIR/33-nvim.sh" "nvimconf/install.sh"
assert_file_contains "10-debloat defines DEBLOAT array" "$MODULES_DIR/10-debloat.sh" "DEBLOAT=\("
assert_file_contains "85-security-stack defines SECURITY_PKGS array" "$MODULES_DIR/85-security-stack.sh" "SECURITY_PKGS=\("
assert_file_contains "setup.sh checks EUID root requirement" "$PROJECT_DIR/scripts/setup.sh" "EUID -eq 0"

test_summary

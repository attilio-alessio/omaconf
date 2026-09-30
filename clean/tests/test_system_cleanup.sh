#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SYSTEM_MODULE="$PROJECT_DIR/scripts/modules/10-system.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "System Cleanup"

assert_file_exists "system module exists" "$SYSTEM_MODULE"
assert_file_contains "system module uses strict mode" "$SYSTEM_MODULE" "set -euo pipefail"
assert_file_contains "system module trims pacman cache" "$SYSTEM_MODULE" "paccache"
assert_file_contains "system module falls back to pacman clean" "$SYSTEM_MODULE" "pacman -Sc"
assert_file_contains "system module removes orphans" "$SYSTEM_MODULE" "pacman -Qtdq"
assert_file_contains "system module vacuums journal" "$SYSTEM_MODULE" "journalctl.*vacuum"
assert_file_contains "system module prunes coredumps" "$SYSTEM_MODULE" "coredump"
assert_file_contains "system module cleans temp dirs" "$SYSTEM_MODULE" "/tmp"
assert_file_contains "system module handles flatpak unused" "$SYSTEM_MODULE" "flatpak uninstall --unused"
assert_file_contains "verify checks orphans" "$PROJECT_DIR/scripts/verify.sh" "pacman -Qtdq"
assert_file_contains "verify checks journal size" "$PROJECT_DIR/scripts/verify.sh" "journalctl --disk-usage"

test_summary

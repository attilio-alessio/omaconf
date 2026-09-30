#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HOME_MODULE="$PROJECT_DIR/scripts/modules/20-home.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Home Cleanup of Debloated Leftovers"

assert_file_exists "home module exists" "$HOME_MODULE"
assert_file_contains "home module uses strict mode" "$HOME_MODULE" "set -euo pipefail"
assert_file_contains "home module iterates homes safely" "$HOME_MODULE" "for u_home in /home/"
assert_file_contains "home module cleans chromium" "$HOME_MODULE" "chromium"
assert_file_contains "home module cleans nautilus" "$HOME_MODULE" "nautilus"
assert_file_contains "home module cleans totem" "$HOME_MODULE" "totem"
assert_file_contains "home module cleans evince" "$HOME_MODULE" "evince"
assert_file_contains "home module cleans dolphin" "$HOME_MODULE" "dolphin"
assert_file_contains "home module cleans okular" "$HOME_MODULE" "okular"
assert_file_contains "home module cleans gwenview" "$HOME_MODULE" "gwenview"
assert_file_contains "home module cleans kdenlive" "$HOME_MODULE" "kdenlive"
assert_file_contains "home module cleans obs-studio" "$HOME_MODULE" "obs-studio"
assert_file_contains "home module cleans obsidian" "$HOME_MODULE" "obsidian"
assert_file_contains "home module sweeps webapp launchers" "$HOME_MODULE" "omarchy-..launch-webapp|webapp-handler"
assert_file_contains "home module prunes thumbnails" "$HOME_MODULE" "thumbnails"
assert_file_contains "home module prunes trash" "$HOME_MODULE" "Trash/files"
assert_file_contains "home module only removes when package absent" "$HOME_MODULE" "pacman -Q"
assert_file_contains "verify checks debloated leftovers" "$PROJECT_DIR/scripts/verify.sh" "check_home_absent"
assert_file_contains "verify checks stale launchers" "$PROJECT_DIR/scripts/verify.sh" "webapp"

test_summary

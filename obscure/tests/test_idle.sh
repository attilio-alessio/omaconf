#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IDLE_MODULE="$PROJECT_DIR/scripts/modules/20-idle.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Idle Obscure"

assert_file_exists "idle module exists" "$IDLE_MODULE"
assert_file_contains "idle module uses strict mode" "$IDLE_MODULE" "set -euo pipefail"
assert_file_contains "idle module removes stay-awake flag" "$IDLE_MODULE" "stay-awake"
assert_file_contains "idle module re-enables screensaver" "$IDLE_MODULE" "screensaver-off"
assert_file_contains "idle module iterates homes safely" "$IDLE_MODULE" "for u_home in /home/"
assert_false "idle module ships no custom locker" "grep -q 'hyprlock\|swaylock' '$IDLE_MODULE'"
assert_file_contains "verify checks idle allowed" "$PROJECT_DIR/scripts/verify.sh" "stay-awake"

test_summary

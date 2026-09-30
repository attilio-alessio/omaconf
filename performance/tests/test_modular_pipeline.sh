#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$PROJECT_DIR/scripts/modules"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Modular Pipeline Architecture & Integrity"

EXPECTED_MODULES=(
    "10-power.sh"
    "20-performance.sh"
)

for m in "${EXPECTED_MODULES[@]}"; do
    mpath="$MODULES_DIR/$m"
    assert_file_exists "module $m exists" "$mpath"
    assert_file_executable "module $m is executable" "$mpath"
    assert_file_contains "module $m has strict mode" "$mpath" "set -euo pipefail"
    assert_file_contains "setup.sh references module $m" "$PROJECT_DIR/scripts/setup.sh" "$m"
done

assert_file_contains "performance setup sources the shared battery policy" "$PROJECT_DIR/scripts/setup.sh" "scripts/modules/89-battery-charge.sh"

assert_file_contains "10-power defines UPower low battery policy" "$MODULES_DIR/10-power.sh" "PercentageLow=20"
assert_file_contains "20-performance defines perf sysctl" "$MODULES_DIR/20-performance.sh" "99-perf.conf"
assert_file_contains "setup.sh checks EUID root requirement" "$PROJECT_DIR/scripts/setup.sh" "EUID -eq 0"

test_summary

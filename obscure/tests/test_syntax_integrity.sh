#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Script Syntax & Code Integrity"

for sh_file in "$PROJECT_DIR"/scripts/*.sh "$PROJECT_DIR"/scripts/modules/*.sh "$PROJECT_DIR"/tests/*.sh "$PROJECT_DIR"/bin/*; do
    [[ -f "$sh_file" ]] || continue
    fname=$(basename "$sh_file")
    assert_true "syntax check: $fname" "bash -n '$sh_file'"
done

assert_file_executable "scripts/setup.sh is executable" "$PROJECT_DIR/scripts/setup.sh"
assert_file_executable "scripts/verify.sh is executable" "$PROJECT_DIR/scripts/verify.sh"
assert_file_executable "scripts/launch.sh is executable" "$PROJECT_DIR/scripts/launch.sh"
assert_file_executable "scripts/run-setup.sh is executable" "$PROJECT_DIR/scripts/run-setup.sh"

for mod in "$PROJECT_DIR"/scripts/modules/*.sh; do
    [[ -f "$mod" ]] || continue
    mname=$(basename "$mod")
    assert_file_executable "module $mname is executable" "$mod"
    assert_file_contains "module $mname uses strict mode" "$mod" "set -euo pipefail"
done

assert_file_contains "setup.sh uses strict mode" "$PROJECT_DIR/scripts/setup.sh" "set -euo pipefail"
assert_file_contains "verify.sh uses strict mode" "$PROJECT_DIR/scripts/verify.sh" "set -uo pipefail"
assert_file_contains "launch.sh uses strict mode" "$PROJECT_DIR/scripts/launch.sh" "set -euo pipefail"
assert_file_contains "run-setup.sh uses strict mode" "$PROJECT_DIR/scripts/run-setup.sh" "set -euo pipefail"

for helper in "$PROJECT_DIR"/bin/*; do
    [[ -f "$helper" ]] || continue
    hname=$(basename "$helper")
    assert_file_executable "helper $hname is executable" "$helper"
    assert_file_contains "helper $hname uses strict mode" "$helper" "set -euo pipefail"
done

test_summary

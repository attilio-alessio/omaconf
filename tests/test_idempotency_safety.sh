#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Automation Idempotency & Safety Rules"

assert_false "No unverified aur_install calls in setup.sh" "grep -q 'aur_install ' '$PROJECT_DIR/scripts/setup.sh' '$PROJECT_DIR'/scripts/modules/*.sh"
assert_false "No yay -S invocations in setup scripts" "grep -q 'yay -S' '$PROJECT_DIR/scripts/setup.sh' '$PROJECT_DIR'/scripts/modules/*.sh"
assert_false "No raw '|| true' failure suppression in scripts" "grep -qE '\|\|[[:space:]]*true\b' '$PROJECT_DIR'/scripts/*.sh '$PROJECT_DIR'/scripts/modules/*.sh '$PROJECT_DIR'/hooks/pre-refresh-pacman.d/* '$PROJECT_DIR'/hooks/post-update.d/*"
assert_false "No raw '|| true' failure suppression in tests" "grep --exclude=test_idempotency_safety.sh -qE '\|\|[[:space:]]*true\b' '$PROJECT_DIR'/tests/*.sh"

check_no_hardcoded_user_paths() {
    local count
    count=$(grep -rnE '/home/[a-zA-Z0-9_-]+/' "$PROJECT_DIR"/scripts/*.sh "$PROJECT_DIR"/scripts/modules/*.sh "$PROJECT_DIR"/hooks/theme-set.d/* "$PROJECT_DIR"/hooks/pre-refresh-pacman.d/* "$PROJECT_DIR"/hooks/post-update.d/* 2>/dev/null | grep -cvE '(/home/\*|/home/\$|PRIMARY_USER)' || :)
    [[ "$count" -eq 0 ]]
}

assert_true "No hardcoded specific user home paths in scripts" "check_no_hardcoded_user_paths"

test_summary

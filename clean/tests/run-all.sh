#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

printf '%b\n' "${BOLD}${CYAN}======================================================${NC}"
printf '%b\n' "${BOLD}${CYAN}        CLEAN TEST SUITE RUNNER        ${NC}"
printf '%b\n' "${BOLD}${CYAN}======================================================${NC}"

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

TEST_FILES=(
    "$SCRIPT_DIR/test_syntax_integrity.sh"
    "$SCRIPT_DIR/test_system_cleanup.sh"
    "$SCRIPT_DIR/test_home_cleanup.sh"
    "$SCRIPT_DIR/test_modular_pipeline.sh"
    "$SCRIPT_DIR/test_idempotency_safety.sh"
)

for tfile in "${TEST_FILES[@]}"; do
    [[ -f "$tfile" ]] || continue
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    tname=$(basename "$tfile")
    if bash "$tfile"; then
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
        printf '%b\n' "${RED}[FAILED] Test suite $tname encountered errors${NC}"
    fi
done

printf '%b\n' "\n${BOLD}${CYAN}======================================================${NC}"
printf '%b\n' "${BOLD}Test Suites Completed: $TOTAL_SUITES | Passed: ${GREEN}$PASSED_SUITES${NC}${BOLD} | Failed: ${RED}$FAILED_SUITES${NC}"
printf '%b\n' "${BOLD}${CYAN}======================================================${NC}"

if [[ $FAILED_SUITES -gt 0 ]]; then
    printf '%b\n' "${RED}${BOLD}Test run failed with $FAILED_SUITES suite failures!${NC}"
    exit 1
fi

printf '%b\n' "${GREEN}${BOLD}All test suites passed successfully!${NC}"
exit 0

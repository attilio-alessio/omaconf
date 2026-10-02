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

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}        OMACONF COMPREHENSIVE TEST SUITE RUNNER        ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

TEST_FILES=(
    "$SCRIPT_DIR/test_syntax_integrity.sh"
    "$SCRIPT_DIR/test_desktop_services.sh"
    "$SCRIPT_DIR/test_lockscreen_regression.sh"
    "$SCRIPT_DIR/test_kernel_hardening.sh"
    "$SCRIPT_DIR/test_auth_pam_access.sh"
    "$SCRIPT_DIR/test_firewall_network.sh"
    "$SCRIPT_DIR/test_debloat_theming.sh"
    "$SCRIPT_DIR/test_security_tooling.sh"
    "$SCRIPT_DIR/test_hardware_power.sh"
    "$SCRIPT_DIR/test_modular_pipeline.sh"
    "$SCRIPT_DIR/test_idempotency_safety.sh"
    "$SCRIPT_DIR/test_i18n_locale.sh"
    "$SCRIPT_DIR/test_config_validity.sh"
    "$SCRIPT_DIR/test_desktop_defaults.sh"
    "$SCRIPT_DIR/test_herdr_menu.sh"
)

for tfile in "${TEST_FILES[@]}"; do
    [[ -f "$tfile" ]] || continue
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    tname=$(basename "$tfile")
    if bash "$tfile"; then
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
        echo -e "${RED}[FAILED] Test suite $tname encountered errors${NC}"
    fi
done

echo -e "\n${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}Test Suites Completed: $TOTAL_SUITES | Passed: ${GREEN}$PASSED_SUITES${NC}${BOLD} | Failed: ${RED}$FAILED_SUITES${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

if [[ $FAILED_SUITES -gt 0 ]]; then
    echo -e "${RED}${BOLD}Test run failed with $FAILED_SUITES suite failures!${NC}"
    exit 1
fi

echo -e "${GREEN}${BOLD}All test suites passed successfully!${NC}"
exit 0

#!/bin/bash

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNED=0

assert_true() {
    local desc="$1"
    local cmd="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if eval "$cmd" &>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}pass${NC} $desc"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}fail${NC} $desc"
    fi
}

assert_false() {
    local desc="$1"
    local cmd="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! eval "$cmd" &>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}pass${NC} $desc"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "  ${RED}fail${NC} $desc"
    fi
}

assert_warn() {
    local desc="$1"
    local cmd="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    if eval "$cmd" &>/dev/null; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}pass${NC} $desc"
    else
        TESTS_WARNED=$((TESTS_WARNED + 1))
        echo -e "  ${YELLOW}warn${NC} $desc"
    fi
}

assert_file_exists() {
    local desc="$1"
    local file="$2"
    assert_true "$desc" "[[ -f '$file' ]]"
}

assert_file_executable() {
    local desc="$1"
    local file="$2"
    assert_true "$desc" "[[ -x '$file' ]]"
}

assert_file_contains() {
    local desc="$1"
    local file="$2"
    local pattern="$3"
    assert_true "$desc" "grep -qE '$pattern' '$file' 2>/dev/null"
}

assert_file_not_contains() {
    local desc="$1"
    local file="$2"
    local pattern="$3"
    assert_false "$desc" "grep -qE '$pattern' '$file' 2>/dev/null"
}

test_section() {
    echo -e "\n${BOLD}${CYAN}[TEST SUITE] $1${NC}"
}

test_summary() {
    echo ""
    echo -e "${BOLD}Summary: Total: $TESTS_RUN | Passed: ${GREEN}$TESTS_PASSED${NC}${BOLD} | Failed: ${RED}$TESTS_FAILED${NC}${BOLD} | Warnings: ${YELLOW}$TESTS_WARNED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        return 1
    fi
    return 0
}

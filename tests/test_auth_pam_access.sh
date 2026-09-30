#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AUTH_MODULE="$PROJECT_DIR/scripts/modules/60-auth.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "PAM Policies & Authentication Controls"

assert_file_exists "auth module exists" "$AUTH_MODULE"
assert_file_contains "auth module configures faillock.conf" "$AUTH_MODULE" "/etc/security/faillock.conf"
assert_file_contains "auth module sets faillock deny = 5" "$AUTH_MODULE" "deny[[:space:]]*=[[:space:]]*5"
assert_file_contains "auth module sets faillock unlock_time = 900" "$AUTH_MODULE" "unlock_time[[:space:]]*=[[:space:]]*900"
assert_file_contains "auth module configures pwquality.conf" "$AUTH_MODULE" "/etc/security/pwquality.conf"
assert_file_contains "auth module sets pwquality minlen = 14" "$AUTH_MODULE" "minlen[[:space:]]*=[[:space:]]*14"
assert_file_contains "auth module configures access.conf" "$AUTH_MODULE" "/etc/security/access.conf"

if [[ -f /etc/security/faillock.conf ]] && grep -qE '^[[:space:]]*deny[[:space:]]*=' /etc/security/faillock.conf 2>/dev/null; then
    assert_file_contains "live faillock deny threshold configured" "/etc/security/faillock.conf" "deny[[:space:]]*=[[:space:]]*5"
    assert_file_contains "live faillock unlock_time configured" "/etc/security/faillock.conf" "unlock_time[[:space:]]*=[[:space:]]*900"
fi

if [[ -f /etc/security/pwquality.conf ]] && grep -qE '^[[:space:]]*minlen[[:space:]]*=' /etc/security/pwquality.conf 2>/dev/null; then
    assert_file_contains "live pwquality minlen set" "/etc/security/pwquality.conf" "minlen[[:space:]]*=[[:space:]]*14"
    assert_file_contains "live pwquality minclass set" "/etc/security/pwquality.conf" "minclass[[:space:]]*=[[:space:]]*4"
fi

if [[ -f /etc/security/access.conf ]] && grep -qE '^\+:root:' /etc/security/access.conf 2>/dev/null; then
    assert_file_contains "live access.conf allows root" "/etc/security/access.conf" "\+:root:LOCAL"
    assert_file_contains "live access.conf allows wheel" "/etc/security/access.conf" "\+:wheel:LOCAL"
    assert_file_contains "live access.conf default deny" "/etc/security/access.conf" "\-:ALL:ALL"
fi

test_summary

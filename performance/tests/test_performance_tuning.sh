#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PERF_MODULE="$PROJECT_DIR/scripts/modules/20-performance.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Runtime Performance Tuning"

assert_file_exists "performance module exists" "$PERF_MODULE"
assert_file_contains "performance module uses strict mode" "$PERF_MODULE" "set -euo pipefail"
assert_file_contains "performance module enables SSD trim" "$PERF_MODULE" "systemctl enable fstrim.timer"
assert_file_contains "performance module persists perf sysctl" "$PERF_MODULE" "99-perf.conf"
assert_file_contains "performance module disables NMI watchdog" "$PERF_MODULE" "kernel.nmi_watchdog = 0"
assert_file_contains "performance module manages power profiles daemon" "$PERF_MODULE" "power-profiles-daemon"

if [[ -f /etc/sysctl.d/99-perf.conf ]]; then
    assert_file_contains "perf sysctl disables NMI watchdog" "/etc/sysctl.d/99-perf.conf" "kernel.nmi_watchdog = 0"
fi

if [[ -f /etc/sysctl.d/99-perf.conf ]] && [[ -f /proc/sys/kernel/nmi_watchdog ]]; then
    assert_true "NMI watchdog disabled live" "[[ \"\$(cat /proc/sys/kernel/nmi_watchdog 2>/dev/null)\" == 0 ]]"
fi

test_summary

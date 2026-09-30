#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
KERNEL_MODULE="$PROJECT_DIR/scripts/modules/50-kernel.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Kernel Sysctl Hardening & Limits"

assert_file_exists "kernel module exists" "$KERNEL_MODULE"
assert_file_contains "kernel module defines 99-security.conf" "$KERNEL_MODULE" "/etc/sysctl.d/99-security.conf"
assert_file_contains "kernel module defines 99-lockdown.conf" "$KERNEL_MODULE" "/etc/sysctl.d/99-lockdown.conf"
assert_file_contains "kernel module configures randomize_va_space" "$KERNEL_MODULE" "kernel.randomize_va_space = 2"
assert_file_contains "kernel module configures kptr_restrict" "$KERNEL_MODULE" "kernel.kptr_restrict = 2"
assert_file_contains "kernel module configures dmesg_restrict" "$KERNEL_MODULE" "kernel.dmesg_restrict = 1"
assert_file_contains "kernel module configures perf_event_paranoid" "$KERNEL_MODULE" "kernel.perf_event_paranoid = 3"
assert_file_contains "kernel module configures unprivileged_bpf_disabled" "$KERNEL_MODULE" "kernel.unprivileged_bpf_disabled = 1"
assert_file_contains "kernel module configures ptrace_scope" "$KERNEL_MODULE" "kernel.yama.ptrace_scope = 1"
assert_file_contains "kernel module configures sysrq" "$KERNEL_MODULE" "kernel.sysrq = 16"
assert_file_contains "kernel module disables coredump" "$KERNEL_MODULE" "DefaultLimitCORE=0"

if [[ -f /etc/sysctl.d/99-security.conf ]]; then
    assert_file_exists "sysctl 99-security.conf exists on system" "/etc/sysctl.d/99-security.conf"
    assert_file_exists "sysctl 99-lockdown.conf exists on system" "/etc/sysctl.d/99-lockdown.conf"
fi

if [[ -f /etc/security/limits.d/99-no-core.conf ]]; then
    assert_file_exists "limits 99-no-core.conf exists on system" "/etc/security/limits.d/99-no-core.conf"
    assert_file_contains "limits.d/99-no-core.conf has hard core 0" "/etc/security/limits.d/99-no-core.conf" "hard[[:space:]]+core[[:space:]]+0"
    assert_file_contains "limits.d/99-no-core.conf has soft core 0" "/etc/security/limits.d/99-no-core.conf" "soft[[:space:]]+core[[:space:]]+0"
fi

check_sysctl_live() {
    local key="$1" expected="$2"
    local path="/proc/sys/${key//./\/}"
    [[ -f "$path" ]] || return 0
    local val
    val=$(cat "$path" 2>/dev/null)
    [[ "$val" == "$expected" ]]
}

if [[ -f /etc/sysctl.d/99-security.conf ]]; then
    assert_true "live kernel.randomize_va_space = 2" "check_sysctl_live kernel.randomize_va_space 2"
    assert_true "live kernel.kptr_restrict = 2" "check_sysctl_live kernel.kptr_restrict 2"
    assert_true "live kernel.dmesg_restrict = 1" "check_sysctl_live kernel.dmesg_restrict 1"
    assert_true "live kernel.perf_event_paranoid = 3" "check_sysctl_live kernel.perf_event_paranoid 3"
    assert_true "live kernel.unprivileged_bpf_disabled = 1" "check_sysctl_live kernel.unprivileged_bpf_disabled 1"
    assert_true "live kernel.yama.ptrace_scope = 1" "check_sysctl_live kernel.yama.ptrace_scope 1"
    assert_true "live kernel.sysrq = 16" "check_sysctl_live kernel.sysrq 16"
    assert_true "live fs.suid_dumpable = 0" "check_sysctl_live fs.suid_dumpable 0"
    assert_true "live net.ipv4.conf.all.rp_filter = 1" "check_sysctl_live net.ipv4.conf.all.rp_filter 1"
    assert_true "live net.ipv4.tcp_syncookies = 1" "check_sysctl_live net.ipv4.tcp_syncookies 1"
    assert_true "live net.ipv4.tcp_rfc1337 = 1" "check_sysctl_live net.ipv4.tcp_rfc1337 1"
fi

test_summary

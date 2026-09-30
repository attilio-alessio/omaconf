#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SEC_MODULE="$PROJECT_DIR/scripts/modules/85-security-stack.sh"
POWER_MODULE="$PROJECT_DIR/scripts/modules/90-hardware-power.sh"
MAINT_MODULE="$PROJECT_DIR/scripts/modules/95-maintenance.sh"
SECURITY_STACK_MODULE="$PROJECT_DIR/scripts/modules/85-security-stack.sh"
SERVICES_MODULE="$PROJECT_DIR/scripts/modules/80-services.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Security Tooling, Isolation & Module Blacklists"

assert_file_exists "security stack module exists" "$SEC_MODULE"
assert_file_contains "security module defines audit rules" "$SEC_MODULE" "/etc/audit/rules.d/hardened.rules"
assert_file_contains "security module configures usbguard" "$SEC_MODULE" "usbguard generate-policy"
assert_file_contains "security module configures fail2ban jail" "$SEC_MODULE" "/etc/fail2ban/jail.local"
assert_file_contains "security module defines apparmor profiles" "$SEC_MODULE" "/etc/apparmor.d/usr.bin.sshd"

assert_file_exists "hardware power module exists" "$POWER_MODULE"
assert_file_contains "hardware module blacklists usb-storage" "$POWER_MODULE" "blacklist usb-storage"
assert_file_contains "hardware module blacklists protocols" "$POWER_MODULE" "disable-protocols.conf"
assert_file_contains "hardware module blacklists firewire" "$POWER_MODULE" "disable-firewire.conf"

assert_file_exists "maintenance module exists" "$MAINT_MODULE"
assert_file_contains "maintenance module schedules weekly audit" "$MAINT_MODULE" "/etc/cron.weekly/security-audit.sh"
assert_file_contains "auditd reload is guarded by a change check" "$SECURITY_STACK_MODULE" "augenrules --check"
assert_file_contains "auditd rules are reloaded idempotently with augenrules" "$SECURITY_STACK_MODULE" "augenrules --load"
assert_file_contains "service disabling is guarded on unit existence" "$SERVICES_MODULE" "unit_installed()"
assert_file_contains "clamav update is deferred when freshclam already runs" "$SECURITY_STACK_MODULE" "pgrep -x freshclam"
assert_file_not_contains "auditd is not restarted via the missing initscripts service wrapper" "$SECURITY_STACK_MODULE" "service auditd restart"
assert_file_contains "ssh config chmod targets the real config files" "$POWER_MODULE" "sshd_config.d/..conf"
assert_file_not_contains "ssh config chmod no longer relies on a non-matching glob" "$POWER_MODULE" "chmod 644 /etc/ssh/..conf 2>"
assert_file_not_contains "pacman cache cleanup no longer pipes yes through pipefail" "$MAINT_MODULE" "yes .. pacman -Scc"
assert_file_contains "pacman cache cleanup uses noconfirm" "$MAINT_MODULE" "pacman -Scc --noconfirm"
assert_file_contains "voxtype global disable is guarded on unit existence" "$MAINT_MODULE" "list-unit-files voxtype.service"
assert_file_contains "maintenance module hardens sudoers" "$MAINT_MODULE" "/etc/sudoers.d/security"

if command -v pacman &>/dev/null && [[ -f /etc/arch-release ]] && [[ -f /etc/audit/rules.d/hardened.rules ]]; then
    for pkg in lynis rkhunter clamav audit usbguard fail2ban apparmor; do
        assert_true "security package $pkg present" "pacman -Q '$pkg' &>/dev/null"
    done
fi

if [[ -f /etc/modprobe.d/disable-usb-storage.conf ]]; then
    assert_file_exists "USB storage blacklist conf exists" "/etc/modprobe.d/disable-usb-storage.conf"
    assert_file_exists "Unsafe protocols blacklist conf exists" "/etc/modprobe.d/disable-protocols.conf"
    assert_file_exists "FireWire blacklist conf exists" "/etc/modprobe.d/disable-firewire.conf"
    assert_file_exists "Legacy filesystems blacklist conf exists" "/etc/modprobe.d/disable-ramfs.conf"
fi

if [[ -f /etc/cron.weekly/security-audit.sh ]]; then
    assert_file_executable "Weekly audit cron script executable" "/etc/cron.weekly/security-audit.sh"
    assert_false "Nonexistent TPM verity file absent" "[[ -f /usr/lib/nvpcr/verity.nvpcr ]]"
fi

if [[ -f /etc/shadow ]]; then
    assert_true "Shadow file permissions 600" "[[ \"\$(stat -c %a /etc/shadow 2>/dev/null)\" == 600 ]]"
    assert_true "Passwd file permissions 644" "[[ \"\$(stat -c %a /etc/passwd 2>/dev/null)\" == 644 ]]"
    assert_true "Group file permissions 644" "[[ \"\$(stat -c %a /etc/group 2>/dev/null)\" == 644 ]]"
fi

test_summary

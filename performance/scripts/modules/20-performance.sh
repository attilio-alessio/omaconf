#!/bin/bash
set -euo pipefail

log "Enabling periodic SSD trim"
systemctl enable fstrim.timer 2>/dev/null || warn "fstrim.timer enable skipped"

log "Disabling NMI watchdog for battery life"
cat > /etc/sysctl.d/99-perf.conf << 'PERF'
kernel.nmi_watchdog = 0
PERF
chmod 644 /etc/sysctl.d/99-perf.conf
sysctl --system >/dev/null 2>&1 || warn "Some sysctl keys failed to apply"

log "Enabling power-profiles-daemon"
if pacman -Q power-profiles-daemon &>/dev/null; then
    systemctl enable power-profiles-daemon.service 2>/dev/null || warn "power-profiles-daemon enable skipped"
fi

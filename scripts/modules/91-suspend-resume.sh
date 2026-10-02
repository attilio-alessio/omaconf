#!/usr/bin/env bash

set -euo pipefail

log "power.suspend_resume"

# Clean up legacy broken deep sleep drop-in if present
rm -f /etc/systemd/sleep.conf.d/99-omaconf-deep-sleep.conf

# Determine safe sleep mode based on hardware and kernel defaults
target_sleep_mode=""
if [[ -r /sys/power/mem_sleep ]]; then
    if grep -q '\[deep\]' /sys/power/mem_sleep; then
        target_sleep_mode="deep"
    elif grep -q '\[s2idle\]' /sys/power/mem_sleep; then
        target_sleep_mode="s2idle"
    elif grep -qw deep /sys/power/mem_sleep; then
        target_sleep_mode="s2idle"
    fi
fi

if [[ -n "$target_sleep_mode" ]]; then
    log "power.suspend_mode" "$target_sleep_mode"
    mkdir -p /etc/systemd/sleep.conf.d
    chmod 755 /etc/systemd/sleep.conf.d
    cat > /etc/systemd/sleep.conf.d/99-omaconf-suspend.conf << SLEEP_CONF
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
AllowSuspendThenHibernate=yes
AllowHybridSleep=yes
MemorySleepMode=$target_sleep_mode
SLEEP_CONF
    chmod 644 /etc/systemd/sleep.conf.d/99-omaconf-suspend.conf
fi

# NVIDIA power management support for suspend/resume
if lsmod 2>/dev/null | grep -qw nvidia || pacman -Q nvidia &>/dev/null || pacman -Q nvidia-open &>/dev/null || pacman -Q nvidia-dkms &>/dev/null; then
    log "power.nvidia_suspend"
    mkdir -p /etc/modprobe.d
    cat > /etc/modprobe.d/nvidia-power-management.conf << 'NVIDIA_CONF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
NVIDIA_CONF
    chmod 644 /etc/modprobe.d/nvidia-power-management.conf

    for svc in nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service; do
        if systemctl list-unit-files "$svc" &>/dev/null; then
            systemctl enable "$svc" 2>/dev/null || warn "power.daemon_reload_skipped"
        fi
    done
fi

systemctl daemon-reload 2>/dev/null || warn "power.daemon_reload_skipped"

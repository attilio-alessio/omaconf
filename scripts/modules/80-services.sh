#!/usr/bin/env bash

set -euo pipefail

log "services.journald_harden"
mkdir -p /etc/systemd/resolved.conf.d
chmod 755 /etc/systemd/resolved.conf.d 2>/dev/null || warn "services.resolved_chmod"
cat > /etc/systemd/resolved.conf.d/hardened.conf << 'RESOLVED'
[Resolve]
LLMNR=no
MulticastDNS=no
RESOLVED
chmod 644 /etc/systemd/resolved.conf.d/hardened.conf 2>/dev/null || warn "services.resolved_conf_chmod"

mkdir -p /etc/systemd/journald.conf.d
chmod 755 /etc/systemd/journald.conf.d 2>/dev/null || warn "services.journald_chmod"
cat > /etc/systemd/journald.conf.d/security.conf << 'JOURNAL'
[Journal]
SystemMaxUse=500M
SystemMaxRetentionSec=30day
Compress=yes
JOURNAL
chmod 644 /etc/systemd/journald.conf.d/security.conf 2>/dev/null || warn "services.journald_conf_chmod"
systemctl restart systemd-journald 2>/dev/null || warn "services.journald_restart"

log "services.disable"
unit_installed() {
    systemctl list-unit-files --no-legend "$1" 2>/dev/null | grep -q .
}
for svc in avahi-daemon cups cups-browsed; do
    if unit_installed "$svc.service"; then
        systemctl disable --now "$svc.service" 2>/dev/null || warn "services.missing" "$svc"
    fi
    if unit_installed "$svc.socket"; then
        systemctl disable --now "$svc.socket" 2>/dev/null || warn "services.socket_missing" "$svc"
    fi
done

log "services.oomd"
systemctl enable systemd-oomd.service || warn "services.oomd_enable_failed"
systemctl enable systemd-oomd.socket || warn "services.oomd_socket_enable_failed"
systemctl start systemd-oomd.socket 2>/dev/null || warn "services.oomd_socket_start_skipped"

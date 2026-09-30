#!/usr/bin/env bash

set -euo pipefail

log "firewall.configure"
if ! pacman -Q ufw &>/dev/null; then
    pacman -S --noconfirm --needed ufw
fi
ufw --force reset 2>/dev/null || warn "firewall.reset_skipped"
ufw default deny incoming
ufw default allow outgoing
ufw allow 53317/udp
ufw allow 53317/tcp
ufw --force enable || warn "firewall.already_active"
systemctl enable ufw.service || warn "firewall.service_enabled"

#!/bin/bash
set -euo pipefail

log "Trimming pacman package cache"
if command -v paccache &>/dev/null; then
    paccache -rk2 --noconfirm 2>/dev/null || warn "paccache trim skipped"
else
    pacman -Sc --noconfirm 2>/dev/null || warn "pacman cache clean skipped"
fi

log "Removing orphan packages"
ORPHANS=""
ORPHANS=$(pacman -Qtdq 2>/dev/null || :)
if [[ -n "$ORPHANS" ]]; then
    pacman -Rns --noconfirm $ORPHANS 2>/dev/null || warn "orphan removal skipped"
fi

log "Vacuuming systemd journal"
journalctl --vacuum-size=200M --vacuum-time=2weeks 2>/dev/null || warn "journal vacuum skipped"

log "Pruning old coredumps"
if [[ -d /var/lib/systemd/coredump ]]; then
    find /var/lib/systemd/coredump -mindepth 1 -mtime +14 -delete 2>/dev/null || warn "coredump prune skipped"
fi

log "Cleaning stale temporary files"
if [[ -d /tmp ]]; then
    find /tmp -mindepth 1 -maxdepth 1 -atime +7 -exec rm -rf {} + 2>/dev/null || warn "/tmp cleanup skipped"
fi
if [[ -d /var/tmp ]]; then
    find /var/tmp -mindepth 1 -maxdepth 1 -atime +14 -exec rm -rf {} + 2>/dev/null || warn "/var/tmp cleanup skipped"
fi

log "Removing unused flatpak runtimes"
if command -v flatpak &>/dev/null; then
    flatpak uninstall --unused -y 2>/dev/null || warn "flatpak unused removal skipped"
fi

log "Refreshing thumbnail and font caches"
fc-cache -f 2>/dev/null || warn "fc-cache refresh skipped"

#!/bin/bash
set -euo pipefail

log "Enforcing idle obscure through the native Omarchy chain"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    _u=$(basename "$u_home")
    rm -f "$u_home/.local/state/omarchy/indicators/stay-awake" 2>/dev/null || warn "stay-awake removal skipped for $_u"
    rm -f "$u_home/.local/state/omarchy/toggles/screensaver-off" 2>/dev/null || warn "screensaver toggle removal skipped for $_u"
done

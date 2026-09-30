#!/usr/bin/env bash

set -euo pipefail

OMAQT_URL="${OMAQT_URL:-}"
OMAQT_DIR="${OMAQT_DIR:-/usr/share/omarchy/omaqt}"

if [[ -z "$OMAQT_URL" ]]; then
    log "omaqt.unconfigured"
    return 0
fi

log "omaqt.sync"
mkdir -p "$(dirname "$OMAQT_DIR")"
if [[ -d "$OMAQT_DIR/.git" ]]; then
    GIT_TERMINAL_PROMPT=0 git -C "$OMAQT_DIR" pull --ff-only 2>/dev/null || warn "omaqt.update_failed"
elif ! GIT_TERMINAL_PROMPT=0 git clone --depth 1 "$OMAQT_URL" "$OMAQT_DIR" 2>/dev/null; then
    warn "omaqt.clone_failed"
fi

if [[ -x "$OMAQT_DIR/install.sh" ]]; then
    log "omaqt.apply"
    "$OMAQT_DIR/install.sh" || err "omaqt.install_failed"
else
    warn "omaqt.install_missing"
fi

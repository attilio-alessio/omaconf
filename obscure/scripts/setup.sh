#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$SCRIPT_DIR/modules"
LOG="${OMASEC_LOG:-$PROJECT_DIR/setup.log}"

if [[ "${OMASEC_LOG_STDOUT:-0}" -eq 0 ]]; then
    exec > >(tee -a "$LOG") 2>&1
fi
umask 077

set -euo pipefail

log() { printf '%s\n' "$1"; }
warn() { printf '%s\n' "warning: $1"; }
err() { printf '%s\n' "error: $1"; exit 1; }

[[ $EUID -eq 0 ]] || err "Root required"

MODULE_FILES=(
    "$MODULES_DIR/10-yazi.sh"
    "$MODULES_DIR/20-idle.sh"
)

for mod in "${MODULE_FILES[@]}"; do
    [[ -f "$mod" ]] || continue
    mod_name=$(basename "$mod")
    log "--> Executing stage: $mod_name"
    # shellcheck source=/dev/null
    source "$mod"
done

log "Shoulder-surfing protection complete. Gated files unlock with the system login password."

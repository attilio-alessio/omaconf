#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PIPELINE="$SCRIPT_DIR/scripts/setup.sh"

# shellcheck source=scripts/lib/i18n.sh
source "$SCRIPT_DIR/scripts/lib/i18n.sh"

i18n_init

[[ $EUID -eq 0 ]] || err "__root_required"
[[ -f "$PIPELINE" ]] || err "__pipeline_missing"

log "app.title"
log "setup.entrypoint"
exec bash "$PIPELINE"

#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
PLUGINS_DIR="$CONFIG_DIR/lua/plugins"
SKEL_DIR="/etc/skel/.config/nvim"
HELPER_FILES="omaconf-helpers.lua omaconf-completion.lua"

I18N_LIB="$(dirname "$SCRIPT_DIR")/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"

i18n_init

if [[ ! -d "$CONFIG_DIR" ]]; then
    if [[ -d "$SKEL_DIR" ]]; then
        mkdir -p "$(dirname "$CONFIG_DIR")"
        cp -r "$SKEL_DIR" "$CONFIG_DIR"
    else
        err "install.nvim_skeleton_missing"
    fi
fi

mkdir -p "$PLUGINS_DIR"

for HELPER_FILE in $HELPER_FILES; do
    if [[ -f "$PLUGINS_DIR/$HELPER_FILE" ]]; then
        cp "$PLUGINS_DIR/$HELPER_FILE" "$PLUGINS_DIR/$HELPER_FILE.bak-$(date +%s)"
    fi
    cp "$SCRIPT_DIR/data/$HELPER_FILE" "$PLUGINS_DIR/$HELPER_FILE"
done

log "install.nvim_done"
log "install.nvim_hint"

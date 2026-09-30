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
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

if [[ ! -d "$CONFIG_DIR" ]]; then
    if [[ -d "$SKEL_DIR" ]]; then
        mkdir -p "$(dirname "$CONFIG_DIR")"
        cp -r "$SKEL_DIR" "$CONFIG_DIR"
    else
        err "install.nvim_skeleton_missing"
    fi
fi

for HELPER_FILE in $HELPER_FILES; do
    install_user_file "$SCRIPT_DIR/data/$HELPER_FILE" "$PLUGINS_DIR/$HELPER_FILE" 600
done

log "install.nvim_done"
log "install.nvim_hint"

#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zed"

I18N_LIB="$(dirname "$SCRIPT_DIR")/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

if command -v jq &>/dev/null && [[ -f "$SCRIPT_DIR/data/linux/settings.json" ]]; then
    jq -s '.[0] * .[1]' "$SCRIPT_DIR/data/settings.json" "$SCRIPT_DIR/data/linux/settings.json" | install_user_content "$CONFIG_DIR/settings.json"
else
    install_user_file "$SCRIPT_DIR/data/settings.json" "$CONFIG_DIR/settings.json"
fi

install_user_file "$SCRIPT_DIR/data/keybindings.json" "$CONFIG_DIR/keymap.json"

if [[ -d "$SCRIPT_DIR/data/snippets" ]] && [[ -n "$(ls -A "$SCRIPT_DIR/data/snippets" 2>/dev/null)" ]]; then
    mkdir -p "$CONFIG_DIR/snippets"
    cp -r "$SCRIPT_DIR/data/snippets/"* "$CONFIG_DIR/snippets/"
fi

log "install.zed_done"

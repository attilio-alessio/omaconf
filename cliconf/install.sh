#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SHARE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omaconf"
MARK_BEGIN="# >>> omaconf helpers >>>"
MARK_END="# <<< omaconf helpers <<<"

I18N_LIB="$(dirname "$SCRIPT_DIR")/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

install_user_file "$SCRIPT_DIR/data/helpers.sh" "$SHARE_DIR/helpers.sh"

if [[ -f "$PROJECT_DIR/hooks/theme-set.d/cli-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/cli-theme" 2>/dev/null || warn "install.theme_sync_skipped"
fi

install_shell_block "$HOME/.bashrc" "$MARK_BEGIN" "$MARK_END" << 'SHELLBLOCK'
[[ -r "$HOME/.local/share/omaconf/helpers.sh" ]] && source "$HOME/.local/share/omaconf/helpers.sh"
[[ -r "$HOME/.config/omaconf/cli-theme.sh" ]] && source "$HOME/.config/omaconf/cli-theme.sh"
SHELLBLOCK

log "install.cli_done"
log "install.cli_hint"

#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/micro"
MARK_BEGIN="# >>> omaconf micro >>>"
MARK_END="# <<< omaconf micro <<<"

I18N_LIB="$(dirname "$SCRIPT_DIR")/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

mkdir -p "$CONFIG_DIR/colorschemes"

if command -v jq &>/dev/null && [[ -s "$CONFIG_DIR/settings.json" ]]; then
    if ! jq -s '.[0] * .[1]' "$CONFIG_DIR/settings.json" "$SCRIPT_DIR/data/settings.json" 2>/dev/null | install_user_content "$CONFIG_DIR/settings.json"; then
        install_user_file "$SCRIPT_DIR/data/settings.json" "$CONFIG_DIR/settings.json"
    fi
else
    install_user_file "$SCRIPT_DIR/data/settings.json" "$CONFIG_DIR/settings.json"
fi

install_user_file "$SCRIPT_DIR/data/bindings.json" "$CONFIG_DIR/bindings.json"

if [[ -x "$PROJECT_DIR/hooks/theme-set.d/micro-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/micro-theme" 2>/dev/null || warn "install.theme_sync_skipped"
fi

install_shell_block "$HOME/.bashrc" "$MARK_BEGIN" "$MARK_END" << 'SHELLBLOCK'
function mh() {
	cat << 'HELP'
micro - essentials                        splits and more
  Ctrl-s ......... save                    Alt-g ....... split vertical
  Ctrl-q ......... quit                    Alt-h ....... split horizontal
  Ctrl-z / Ctrl-y  undo / redo             Ctrl-e ...... command line
  Ctrl-f/n/p ..... find / next/prev
  Ctrl-a/c/x/v ... select copy cut paste
  Ctrl-k / Ctrl-d  cut line / duplicate line
  Ctrl-g ......... full help inside micro
HELP
}
SHELLBLOCK

log "install.micro_done"

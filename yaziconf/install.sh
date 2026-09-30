#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
FM_DESKTOP="yazi-terminal.desktop"
MARK_BEGIN="# >>> omablot yazi >>>"
MARK_END="# <<< omablot yazi <<<"

I18N_LIB="$(dirname "$SCRIPT_DIR")/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"

i18n_init

mkdir -p "$CONFIG_DIR"

for cfg in yazi.toml theme.toml; do
    if [[ -f "$CONFIG_DIR/$cfg" ]] && ! cmp -s "$SCRIPT_DIR/data/$cfg" "$CONFIG_DIR/$cfg"; then
        cp "$CONFIG_DIR/$cfg" "$CONFIG_DIR/$cfg.bak-$(date +%s)"
    fi
    cp "$SCRIPT_DIR/data/$cfg" "$CONFIG_DIR/$cfg"
done

if [[ -x "$PROJECT_DIR/hooks/theme-set.d/yazi-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/yazi-theme" 2>/dev/null || warn "install.theme_sync_skipped"
fi

mkdir -p "$APP_DIR"
cp "$SCRIPT_DIR/data/$FM_DESKTOP" "$APP_DIR/$FM_DESKTOP"
update-desktop-database "$APP_DIR" 2>/dev/null || warn "install.desktopdb_skipped"

xdg-mime default "$FM_DESKTOP" inode/directory 2>/dev/null || warn "install.xdgmime_skipped"
gio mime inode/directory "$FM_DESKTOP" 2>/dev/null || warn "install.giomime_skipped"

_mimeapps="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
if [[ -f "$_mimeapps" ]]; then
    if grep -q '^inode/directory=' "$_mimeapps"; then
        sed -i "s|^inode/directory=.*|inode/directory=$FM_DESKTOP|" "$_mimeapps"
    else
        sed -i "/^\[Default Applications\]/a inode/directory=$FM_DESKTOP" "$_mimeapps"
    fi
fi

if [[ -f "$HOME/.bashrc" ]]; then
    sed -i "\\|$MARK_BEGIN|,\\|$MARK_END|d" "$HOME/.bashrc"
    cat >> "$HOME/.bashrc" << 'SHELLBLOCK'
# >>> omablot yazi >>>
function ya() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
function yh() {
	cat << 'HELP'
yazi - navigation (vim-style)           quick openers
  k/j up/down .... up/down               text/md ..... micro
  h/l left/right . back/forward          pdf ....... zathura
  gg/G ........... start/end             images ...... imv
  z/Z ............ jump with fzf/zoxide  audio/video . mpv
  o/O ............ open / open-with      archives .... extract here
  y/x/p .......... copy/cut/paste
  Tab ............ select, v visual      ~ ........... full help
  : .............. command, Q quit       ya .......... quit staying here
HELP
}
# <<< omablot yazi <<<
SHELLBLOCK
fi

log "install.yazi_done"

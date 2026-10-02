#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OMAQT_MODULE="$PROJECT_DIR/scripts/modules/32-omaqt.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Independent Desktop Applications"

ENV_MODULE="$PROJECT_DIR/scripts/modules/00-env.sh"
THEMING_MODULE="$PROJECT_DIR/scripts/modules/30-theming.sh"

assert_file_contains "env module defines the per-user command helper" "$ENV_MODULE" "user_as()"
assert_file_contains "per-user helper forwards HOME" "$ENV_MODULE" 'HOME=.home.'
assert_file_contains "per-user helper forwards the runtime dir" "$ENV_MODULE" 'XDG_RUNTIME_DIR=.runtime.'
assert_file_contains "per-user helper forwards the session bus" "$ENV_MODULE" 'DBUS_SESSION_BUS_ADDRESS=.bus.'
assert_file_contains "per-user helper forwards the active language" "$ENV_MODULE" 'OMACONF_LANG=.OMACONF_LANG.'
assert_file_contains "omarchy_as delegates to the per-user helper" "$ENV_MODULE" 'OMARCHY_PATH=.OMARCHY_PATH. omarchy'

assert_file_contains "theming runs hooks through the per-user helper" "$THEMING_MODULE" 'user_as .._user. bash .._hook_dir/.hook_name.'
assert_file_not_contains "omaqt does not route xdg-mime through omarchy" "$OMAQT_MODULE" 'omarchy_as "$_user" xdg-mime'
assert_file_not_contains "omaqt does not route gio through omarchy" "$OMAQT_MODULE" 'omarchy_as "$_user" gio'


DEBLOAT_MODULE="$PROJECT_DIR/scripts/modules/10-debloat.sh"
DEFAULTS_MODULE="$PROJECT_DIR/scripts/modules/20-defaults.sh"
SHELL_PLUGINS_MODULE="$PROJECT_DIR/scripts/modules/35-shell-plugins.sh"

assert_file_not_contains "defaults never sets the browser as root" "$DEFAULTS_MODULE" 'omarchy default browser'

assert_file_contains "debloat module merges pins instead of overwriting" "$DEBLOAT_MODULE" "EXISTING_PINS"
assert_file_contains "debloat module installs persistence hooks" "$DEBLOAT_MODULE" "99-omaconf-persist"
assert_file_contains "yaziconf installer enforces yazi file manager" "$PROJECT_DIR/yaziconf/install.sh" 'inode/directory'
assert_file_contains "yaziconf installer pins the terminal desktop entry" "$PROJECT_DIR/yaziconf/install.sh" 'FM_DESKTOP="yazi-terminal.desktop"' 
assert_file_contains "yaziconf installer registers the desktop entry" "$PROJECT_DIR/yaziconf/install.sh" "xdg-mime default"
assert_file_contains "defaults module records file-manager state" "$DEFAULTS_MODULE" "defaults/file-manager"
assert_file_contains "defaults module rebinds file manager keys to yazi" "$DEFAULTS_MODULE" "omaconf-yazi-fm"
assert_file_contains "defaults module provisions herdrconf menu" "$DEFAULTS_MODULE" "herdrconf/install.sh"
assert_file_contains "shell plugins module uses canonical omamp source" "$SHELL_PLUGINS_MODULE" "omaconf/omamp.git"
assert_file_contains "env module defines omarchy_as helper" "$PROJECT_DIR/scripts/modules/00-env.sh" "omarchy_as\(\)"
assert_file_contains "omarchy_as forwards the user session bus" "$PROJECT_DIR/scripts/modules/00-env.sh" "DBUS_SESSION_BUS_ADDRESS"
assert_file_contains "defaults module routes browser through omarchy_as" "$DEFAULTS_MODULE" "omarchy_as"
assert_file_contains "setup.sh references nvim module" "$PROJECT_DIR/scripts/setup.sh" "33-nvim.sh"
assert_file_contains "setup.sh references shell plugins module" "$PROJECT_DIR/scripts/setup.sh" "35-shell-plugins.sh"
assert_file_contains "nvim module provisions root nvimconf" "$PROJECT_DIR/scripts/modules/33-nvim.sh" "nvimconf/install.sh"

PERSIST_PRE="$PROJECT_DIR/hooks/pre-refresh-pacman.d/99-omaconf-persist"
assert_file_exists "pre-refresh persist hook exists in repo" "$PERSIST_PRE"
assert_file_executable "pre-refresh persist hook executable" "$PERSIST_PRE"
assert_file_contains "pre-refresh hook re-merges IgnorePkg" "$PERSIST_PRE" "IgnorePkg"

PERSIST_POST="$PROJECT_DIR/hooks/post-update.d/99-omaconf-persist"
assert_file_exists "post-update persist hook exists in repo" "$PERSIST_POST"
assert_file_executable "post-update persist hook executable" "$PERSIST_POST"
assert_file_contains "post-update hook reapplies yazi default" "$PERSIST_POST" "yazi-terminal.desktop inode/directory"
assert_file_contains "post-update hook reapplies zathura default" "$PERSIST_POST" "org.pwmt.zathura.desktop application/pdf"
assert_file_contains "post-update hook reapplies image defaults" "$PERSIST_POST" "imv.desktop image/png"
assert_file_contains "post-update hook reapplies media defaults" "$PERSIST_POST" "mpv.desktop video/mp4"
assert_file_contains "post-update hook removes crash-watch" "$PERSIST_POST" "omarchy-crash-watch.service"

assert_file_exists "omaqt integration module exists" "$OMAQT_MODULE"
assert_file_executable "omaqt integration module executable" "$OMAQT_MODULE"
assert_file_contains "omaqt integration module uses strict mode" "$OMAQT_MODULE" "set -euo pipefail"
assert_file_contains "setup.sh references omaqt module" "$PROJECT_DIR/scripts/setup.sh" "32-omaqt.sh"
assert_file_not_contains "omaqt module hardcodes no upstream repo URL" "$OMAQT_MODULE" "github.com/omasec-org"
assert_file_contains "omaqt module takes its URL from the environment" "$OMAQT_MODULE" '^OMAQT_URL='
assert_file_contains "omaqt module defaults the URL to empty" "$OMAQT_MODULE" 'OMAQT_URL:-'
assert_file_contains "omaqt module logs a clean skip when unconfigured" "$OMAQT_MODULE" "omaqt.unconfigured"
assert_file_contains "omaqt module returns early because it is sourced" "$OMAQT_MODULE" "return 0"
assert_file_not_contains "omaqt module never exits the sourcing setup" "$OMAQT_MODULE" "exit 0"
assert_file_contains "omaqt module delegates to omaqt installer" "$OMAQT_MODULE" "install.sh"
assert_file_contains "omaqt module tracks omaqt checkout" "$OMAQT_MODULE" "OMAQT_DIR"
assert_file_contains "omaqt module applies omaqt under usr/share/omarchy" "$OMAQT_MODULE" "/usr/share/omarchy/omaqt"
assert_file_contains "omaqt module degrades gracefully on clone failure" "$OMAQT_MODULE" "|| warn"
assert_file_not_contains "omaqt module no longer duplicates the yazi default" "$OMAQT_MODULE" "inode/directory"

assert_file_contains "defaults module owns the yazi-terminal directory default" "$DEFAULTS_MODULE" "yazi-terminal.desktop"
assert_file_contains "defaults module falls back to system yazi.desktop" "$DEFAULTS_MODULE" '_fm="yazi.desktop"'

OMAQT_DIR="/usr/share/omarchy/omaqt"
if [[ -x "$OMAQT_DIR/install.sh" ]]; then
    for app in yazi zathura imv mpv papirus-icon-theme; do
        assert_file_contains "omaqt installer installs $app" "$OMAQT_DIR/install.sh" "$app"
    done
    for app in nautilus totem evince eog yaru-icon-theme dolphin okular gwenview \
        xdg-desktop-portal-kde plasma-integration breeze breeze-gtk; do
        assert_file_contains "omaqt installer pins removed $app" "$OMAQT_DIR/install.sh" "$app"
    done
    assert_file_contains "omaqt installer removes GNOME apps" "$OMAQT_DIR/install.sh" "Removing GNOME default applications"
    assert_file_contains "omaqt installer removes KDE apps" "$OMAQT_DIR/install.sh" "Removing the KDE desktop stack"
    assert_file_contains "omaqt installer removes packages recursively" "$OMAQT_DIR/install.sh" "Rns --noconfirm"
    assert_false "omaqt installer does not install kde portal" "sed -n '/^APP_PKGS=/,/^)/p' $OMAQT_DIR/install.sh | grep -q 'xdg-desktop-portal-kde'"
    assert_file_contains "omaqt installer removes system portal override" "$OMAQT_DIR/install.sh" "portals.conf"
    assert_file_contains "omaqt installer sets zathura mime default" "$OMAQT_DIR/install.sh" "org.pwmt.zathura.desktop application/pdf"
    assert_file_contains "omaqt installer sets imv mime default" "$OMAQT_DIR/install.sh" "imv.desktop image"
    assert_file_contains "omaqt installer sets mpv mime default" "$OMAQT_DIR/install.sh" "mpv.desktop video"
    assert_true "omaqt installer sets a yazi mime default" \
        "grep -qE 'yazi(-terminal)?\\.desktop inode/directory' '$OMAQT_DIR/install.sh'"
    assert_file_contains "omaqt installer cleans stale KDE hooks" "$OMAQT_DIR/install.sh" "kde-folder-color"
fi

if command -v pacman &>/dev/null && [[ -f /etc/arch-release ]] && [[ -f /etc/pacman.d/omaconf/ignore-pkgs.list ]]; then
    for app in yazi zathura imv mpv papirus-icon-theme; do
        assert_true "$app installed" "pacman -Q $app &>/dev/null"
    done
    for app in nautilus totem evince eog yaru-icon-theme dolphin okular gwenview \
        xdg-desktop-portal-kde plasma-integration breeze breeze-gtk haruna; do
        assert_false "$app not installed" "pacman -Q $app &>/dev/null"
    done
fi

if command -v pacman &>/dev/null && [[ -f /etc/arch-release ]] && [[ -f /etc/mime.types ]]; then
    assert_true "pdf default is zathura" "xdg-mime query default application/pdf 2>/dev/null | grep -q 'zathura'"
    assert_true "image default is imv" "xdg-mime query default image/jpeg 2>/dev/null | grep -q 'imv'"
    assert_true "video default is mpv" "xdg-mime query default video/mp4 2>/dev/null | grep -q 'mpv'"
    assert_true "directory default is yazi-terminal" "xdg-mime query default inode/directory 2>/dev/null | grep -q 'yazi-terminal'"
fi

if [[ -f /etc/xdg/xdg-desktop-portal/portals.conf ]]; then
    assert_false "no system portal override" "grep -q '^default=kde' /etc/xdg/xdg-desktop-portal/portals.conf"
fi

test_summary
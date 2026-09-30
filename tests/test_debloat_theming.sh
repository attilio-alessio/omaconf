#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEBLOAT_MODULE="$PROJECT_DIR/scripts/modules/10-debloat.sh"
DEFAULTS_MODULE="$PROJECT_DIR/scripts/modules/20-defaults.sh"
THEMING_MODULE="$PROJECT_DIR/scripts/modules/30-theming.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Debloat, Application Parity & Theming"

assert_file_exists "debloat module exists" "$DEBLOAT_MODULE"
assert_file_contains "debloat module defines package removal" "$DEBLOAT_MODULE" "pacman -Rns"
assert_file_contains "debloat module defines IgnorePkg pinning" "$DEBLOAT_MODULE" "IgnorePkg.*MERGED_PINS"
assert_file_contains "debloat module merges pins instead of overwriting" "$DEBLOAT_MODULE" "EXISTING_PINS"
assert_file_contains "debloat module installs persistence hooks" "$DEBLOAT_MODULE" "99-omablot-persist"

assert_file_exists "defaults module exists" "$DEFAULTS_MODULE"
assert_file_contains "defaults module configures brave-origin" "$DEFAULTS_MODULE" "brave-origin"
assert_file_contains "defaults module configures micro editor" "$DEFAULTS_MODULE" "micro"
assert_file_contains "defaults module configures yazi file manager" "$DEFAULTS_MODULE" "yazi"
assert_file_contains "defaults module installs Kitty" "$DEFAULTS_MODULE" "pacman -S --noconfirm --needed kitty"
assert_file_contains "defaults module configures imv image viewer" "$DEFAULTS_MODULE" "imv"
assert_file_contains "defaults module configures trash-cli safe delete" "$DEFAULTS_MODULE" "trash-cli"
assert_file_contains "defaults module configures mpv player" "$DEFAULTS_MODULE" "mpv"
assert_file_contains "defaults module configures zathura pdf viewer" "$DEFAULTS_MODULE" "zathura"

assert_file_exists "theming module exists" "$THEMING_MODULE"
assert_file_contains "theming module installs hooks" "$THEMING_MODULE" "hooks/theme-set.d"
assert_file_exists "theme preview apply helper exists" "$PROJECT_DIR/theme-previews/apply.sh"
assert_file_contains "theme preview apply creates missing user overlays" "$PROJECT_DIR/theme-previews/apply.sh" 'install -d -m 700'
assert_file_contains "theme preview apply clears selector cache" "$PROJECT_DIR/theme-previews/apply.sh" 'theme-selector'

if command -v pacman &>/dev/null && [[ -f /etc/arch-release ]] && [[ -f /etc/pacman.d/omablot/ignore-pkgs.list ]]; then
    assert_true "herdr installed" "pacman -Q herdr &>/dev/null"
    assert_true "gum installed" "pacman -Q gum &>/dev/null"
    assert_true "brave-origin-bin installed" "pacman -Q brave-origin-bin &>/dev/null"
    assert_true "micro installed" "pacman -Q micro &>/dev/null"
    assert_true "yazi installed" "pacman -Q yazi &>/dev/null"
    assert_true "imv installed" "pacman -Q imv &>/dev/null"
    assert_true "mpv installed" "pacman -Q mpv &>/dev/null"
    assert_true "zathura installed" "pacman -Q zathura &>/dev/null"
    assert_true "btop installed" "pacman -Q btop &>/dev/null"
    assert_true "capitaine-cursors installed" "pacman -Q capitaine-cursors &>/dev/null"
    assert_true "papirus-icon-theme installed" "pacman -Q papirus-icon-theme &>/dev/null"

    assert_true "kitty terminal installed" "pacman -Q kitty &>/dev/null"
    assert_false "foot terminal removed" "pacman -Q foot &>/dev/null"
    for debloated in chromium nautilus yaru-icon-theme system-config-printer totem evince eog dolphin okular gwenview xdg-desktop-portal-kde breeze breeze-gtk haruna kdenlive obs-studio libreoffice-fresh obsidian gnome-disk-utility gnome-themes-extra foot; do
        assert_false "debloat verified: $debloated removed" "pacman -Q '$debloated' &>/dev/null"
    done
    assert_false "docker daemon absent" "command -v dockerd &>/dev/null"
    assert_true "podman installed" "pacman -Q podman &>/dev/null"
fi

if [[ -f /etc/pacman.d/omablot/ignore-pkgs.list ]]; then
    assert_file_exists "pacman ignore-pkgs.list exists" "/etc/pacman.d/omablot/ignore-pkgs.list"
    assert_file_contains "pacman.conf has IgnorePkg" "/etc/pacman.conf" "^IgnorePkg"
fi

HOOK_FILE="$PROJECT_DIR/hooks/theme-set.d/folder-color"
assert_file_exists "folder-color hook exists in repo" "$HOOK_FILE"
assert_file_executable "folder-color hook executable" "$HOOK_FILE"

MICRO_HOOK="$PROJECT_DIR/hooks/theme-set.d/micro-theme"
assert_file_exists "micro-theme hook exists in repo" "$MICRO_HOOK"
assert_file_executable "micro-theme hook executable" "$MICRO_HOOK"

PERSIST_PRE="$PROJECT_DIR/hooks/pre-refresh-pacman.d/99-omablot-persist"
assert_file_exists "pre-refresh persist hook exists in repo" "$PERSIST_PRE"
assert_file_executable "pre-refresh persist hook executable" "$PERSIST_PRE"
assert_file_contains "pre-refresh hook re-merges IgnorePkg" "$PERSIST_PRE" "IgnorePkg"

PERSIST_POST="$PROJECT_DIR/hooks/post-update.d/99-omablot-persist"
assert_file_exists "post-update persist hook exists in repo" "$PERSIST_POST"
assert_file_executable "post-update persist hook executable" "$PERSIST_POST"
assert_file_contains "post-update hook reapplies yazi default" "$PERSIST_POST" "yazi-terminal.desktop inode/directory"
assert_file_contains "post-update hook reapplies termfilechooser routing" "$PERSIST_POST" "FileChooser=termfilechooser"

assert_file_exists "sprint plan exists" "$PROJECT_DIR/docs/SPRINTS.md"
assert_file_contains "sprint plan freezes current defaults" "$PROJECT_DIR/docs/SPRINTS.md" "brave-origin"
assert_file_exists "plugin index exists" "$PROJECT_DIR/plugins/index.json"
assert_file_contains "plugin index references omamp" "$PROJECT_DIR/plugins/index.json" "omamp"

assert_file_exists "zedconf install script exists" "$PROJECT_DIR/zedconf/install.sh"
assert_file_exists "microconf install script exists" "$PROJECT_DIR/microconf/install.sh"
assert_file_exists "microconf settings exists" "$PROJECT_DIR/microconf/data/settings.json"
assert_file_exists "microconf bindings exists" "$PROJECT_DIR/microconf/data/bindings.json"
assert_file_exists "yaziconf install script exists" "$PROJECT_DIR/yaziconf/install.sh"
assert_file_exists "yaziconf yazi.toml template exists" "$PROJECT_DIR/yaziconf/data/yazi.toml"
assert_file_contains "defaults module provisions yaziconf" "$DEFAULTS_MODULE" "yaziconf"
assert_file_contains "defaults module enforces gio file manager default" "$DEFAULTS_MODULE" "gio mime inode/directory"
assert_file_contains "defaults module enforces mimeapps file manager" "$DEFAULTS_MODULE" "mimeapps"
assert_file_contains "defaults module records file-manager state" "$DEFAULTS_MODULE" "defaults/file-manager"
assert_file_contains "defaults module rebinding hypr file manager keys" "$DEFAULTS_MODULE" "omablot-yazi-fm"
assert_file_contains "defaults module installs termfilechooser portal" "$DEFAULTS_MODULE" "xdg-desktop-portal-termfilechooser"
assert_file_contains "defaults module routes FileChooser to termfilechooser" "$DEFAULTS_MODULE" "FileChooser=termfilechooser"
assert_file_contains "yaziconf template uses current file placeholders" "$PROJECT_DIR/yaziconf/data/yazi.toml" "%s"
assert_file_contains "yaziconf template respects EDITOR with micro fallback" "$PROJECT_DIR/yaziconf/data/yazi.toml" "EDITOR:-micro"
assert_false "yaziconf template has no legacy placeholders" "grep -qF -e '\"\$@\"' -e '\"\$1\"' '$PROJECT_DIR/yaziconf/data/yazi.toml'"

test_icon_mapping() {
    local theme="$1" expected="$2"
    local mapped
    case "$theme" in
        white|flexoki-light|catppuccin-latte|solarized-light) mapped="Papirus" ;;
        *) mapped="Papirus-Dark" ;;
    esac
    [[ "$mapped" == "$expected" ]]
}

assert_true "icon map: everforest -> Papirus-Dark" "test_icon_mapping 'everforest' 'Papirus-Dark'"
assert_true "icon map: vantablack -> Papirus-Dark" "test_icon_mapping 'vantablack' 'Papirus-Dark'"
assert_true "icon map: white -> Papirus" "test_icon_mapping 'white' 'Papirus'"
assert_true "icon map: flexoki-light -> Papirus" "test_icon_mapping 'flexoki-light' 'Papirus'"
assert_true "icon map: catppuccin-latte -> Papirus" "test_icon_mapping 'catppuccin-latte' 'Papirus'"
assert_true "icon map: solarized-light -> Papirus" "test_icon_mapping 'solarized-light' 'Papirus'"
assert_true "icon map: default -> Papirus-Dark" "test_icon_mapping 'default' 'Papirus-Dark'"

test_summary

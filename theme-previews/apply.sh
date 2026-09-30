#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_USER="${SUDO_USER:-${PKEXEC_UID:-$USER}}"
SYSTEM_SCOPE=0

if [[ "${1:-}" == "--system" ]]; then
    SYSTEM_SCOPE=1
    shift
fi

if [[ "$TARGET_USER" =~ ^[0-9]+$ ]]; then
    TARGET_USER="$(id -nu "$TARGET_USER")"
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$TARGET_HOME" ]] || TARGET_HOME="$HOME"

if (($#)); then
    themes=("$@")
else
    mapfile -t themes < <(find "$SCRIPT_DIR" -mindepth 2 -maxdepth 2 -type f -name preview.png -printf '%h\n' | sed 's|.*/||' | sort)
fi

if ((SYSTEM_SCOPE)); then
    [[ $EUID -eq 0 ]] || { printf 'System scope requires root.\n' >&2; exit 1; }
    (($#)) || {
        printf 'System scope requires explicit themes so stock artwork is never pinned.\n' >&2
        exit 2
    }
    source "$PROJECT_DIR/scripts/lib/theme-preview.sh"
fi

for theme_name in "${themes[@]}"; do
    theme_dir="$SCRIPT_DIR/$theme_name"
    [[ -d "$theme_dir" ]] || continue
    src="$theme_dir/preview.png"
    [[ -f "$src" ]] || continue

    user_dir="$TARGET_HOME/.config/omarchy/themes/$theme_name"
    install -d -m 700 -o "$TARGET_USER" -g "$TARGET_USER" "$user_dir"
    if [[ -f "$user_dir/preview.png" ]]; then
        [[ -f "$user_dir/preview.bak.png" ]] || cp "$user_dir/preview.png" "$user_dir/preview.bak.png"
    fi
    install -m 600 -o "$TARGET_USER" -g "$TARGET_USER" "$src" "$user_dir/preview.png"
    touch "$user_dir"
    if [[ -f "$user_dir/preview.bak.png" ]]; then
        chown "$TARGET_USER:$TARGET_USER" "$user_dir/preview.bak.png"
    fi

    if ((SYSTEM_SCOPE)); then
        system_dir="/usr/share/omarchy/themes/$theme_name"
        [[ -d "$system_dir" ]] || continue
        theme_preview_store_overlay "$src" "$theme_name" || {
            printf 'Failed to record the system overlay for %s\n' "$theme_name" >&2
            exit 1
        }
        install -m 644 -o root -g root "$src" "$system_dir/preview.png"
    fi
done

rm -rf "$TARGET_HOME/.cache/omarchy/theme-selector"
printf '%s\n' "preview applied"

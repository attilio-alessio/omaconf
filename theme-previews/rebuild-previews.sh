#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
STAGING_DIR=/tmp/homeshot
STAGING_OWNED=0
KITTY_PID=""
CAPTURE_WORKSPACE=""

if (($#)); then
    themes=("$@")
else
    printf 'Usage: %s <theme> [theme...]\n' "${0##*/}" >&2
    printf 'Previews stay stock upstream artwork unless a theme is named explicitly.\n' >&2
    exit 2
fi

ARTIFACTS_DIR="$(mktemp -d /tmp/omaconf-preview-artifacts.XXXXXX)"
ORIGINAL_THEME="$(omarchy theme current)"
ORIGINAL_WORKSPACE="$(hyprctl -j activeworkspace | jq -r '.id')"

YAZI_TILE_CANVAS="1800x1012"
YAZI_TILE_OFFSET="906,520"
YAZI_TILE_SIZE="878x480"

cleanup() {
    local status=$?
    if [[ -n "$KITTY_PID" ]] && kill -0 "$KITTY_PID" 2>/dev/null; then
        kill -- "-$KITTY_PID" 2>/dev/null || kill "$KITTY_PID" 2>/dev/null || :
        wait "$KITTY_PID" 2>/dev/null || :
    fi
    hyprctl dispatch "hl.dsp.focus({ workspace = \"$ORIGINAL_WORKSPACE\" })" >/dev/null 2>&1 || :
    omarchy theme set "$ORIGINAL_THEME" >/dev/null 2>&1 || status=1
    if ((STAGING_OWNED)); then
        rm -rf -- "$STAGING_DIR"
    fi
    rm -rf -- "$ARTIFACTS_DIR"
    exit "$status"
}
trap cleanup EXIT INT TERM

mkdir -m 700 -- "$STAGING_DIR"
STAGING_OWNED=1

command -v jq >/dev/null
command -v grim >/dev/null
command -v magick >/dev/null
command -v setsid >/dev/null

for folder in Desktop Documents Downloads Dropbox Music Pictures Public Videos; do
    mkdir -p "$STAGING_DIR/$folder"
done

for candidate in {90..999}; do
    if ! hyprctl -j workspaces | jq -e --argjson id "$candidate" '.[] | select(.id == $id)' >/dev/null; then
        CAPTURE_WORKSPACE="$candidate"
        break
    fi
done
[[ -n "$CAPTURE_WORKSPACE" ]] || { printf 'No free capture workspace is available.\n' >&2; exit 1; }

for theme in "${themes[@]}"; do
    [[ "$theme" =~ ^[a-z0-9-]+$ ]] || { printf 'Invalid theme slug: %s\n' "$theme" >&2; exit 2; }
    theme_dir="/usr/share/omarchy/themes/$theme"
    stock_preview="$theme_dir/preview.png"
    colors_file="$theme_dir/colors.toml"
    [[ -r "$stock_preview" && -r "$colors_file" ]] || {
        printf 'Theme assets are missing for %s\n' "$theme" >&2
        exit 1
    }
    printf 'Rebuilding preview for %s\n' "$theme"
    OMARCHY_THEME_HEADLESS=1 OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy theme set "$theme"
    if [[ -x "$PROJECT_DIR/hooks/theme-set.d/yazi-theme" ]]; then
        bash "$PROJECT_DIR/hooks/theme-set.d/yazi-theme"
    fi
    hyprctl dispatch "hl.dsp.focus({ workspace = \"$CAPTURE_WORKSPACE\" })" >/dev/null

    accent="$(awk -F '"' '/^[[:space:]]*accent[[:space:]]*=/{print $2; exit}' "$colors_file")"
    [[ "$accent" =~ ^#[[:xdigit:]]{6}$ ]] || accent='#89b4fa'
    background="$(awk -F '"' '/^[[:space:]]*background[[:space:]]*=/{print $2; exit}' "$colors_file")"
    [[ "$background" =~ ^#[[:xdigit:]]{6}$ ]] || background='#101010'
    normalized_preview="$ARTIFACTS_DIR/$theme-stock.png"
    cp -- "$stock_preview" "$normalized_preview"
    source "$PROJECT_DIR/scripts/lib/theme-preview.sh"
    THEME_PREVIEW_CANVAS="$YAZI_TILE_CANVAS"
    theme_preview_normalize_file "$normalized_preview" || {
        printf 'Preview normalization failed for %s\n' "$theme" >&2
        exit 1
    }
    IFS='x' read -r canvas_width canvas_height <<< "$(identify -format '%wx%h' "$normalized_preview")"
    IFS='x' read -r ref_canvas_width ref_canvas_height <<< "$YAZI_TILE_CANVAS"
    IFS=',' read -r ref_tile_x ref_tile_y <<< "$YAZI_TILE_OFFSET"
    IFS='x' read -r ref_tile_width ref_tile_height <<< "$YAZI_TILE_SIZE"
    tile_x=$((ref_tile_x * canvas_width / ref_canvas_width))
    tile_y=$((ref_tile_y * canvas_height / ref_canvas_height))
    tile_width=$((ref_tile_width * canvas_width / ref_canvas_width))
    tile_height=$((ref_tile_height * canvas_height / ref_canvas_height))

    setsid kitty --class termfilemanager \
        --start-as=fullscreen \
        -o font_size=18 \
        -o window_padding_width=10 \
        -o background_opacity=1.0 \
        -e yazi "$STAGING_DIR" &
    KITTY_PID=$!

    address=""
    for _ in {1..60}; do
        address="$(hyprctl -j clients | jq -r --argjson pid "$KITTY_PID" \
            '.[] | select(.pid == $pid and .class == "termfilemanager") | .address' | head -n 1)"
        [[ -n "$address" ]] && break
        sleep 0.1
    done
    [[ -n "$address" ]] || { printf 'Kitty/Yazi window did not appear for %s\n' "$theme" >&2; exit 1; }

    geometry=""
    client_workspace=""
    for _ in {1..60}; do
        client="$(hyprctl -j clients | jq -c --arg address "$address" '.[] | select(.address == $address)')"
        if [[ -n "$client" ]]; then
            client_workspace="$(jq -r '.workspace.id' <<< "$client")"
            geometry="$(jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' <<< "$client")"
            [[ "$client_workspace" == "$CAPTURE_WORKSPACE" ]] && break
        fi
        sleep 0.1
    done
    [[ "$client_workspace" == "$CAPTURE_WORKSPACE" ]] || {
        printf 'Kitty window was not isolated on workspace %s for %s: %s\n' "$CAPTURE_WORKSPACE" "$theme" "$geometry" >&2
        exit 1
    }
    sleep 1

    shot="$ARTIFACTS_DIR/$theme.png"
    grim -g "$geometry" "$shot"
    output_dir="$SCRIPT_DIR/$theme"
    mkdir -p "$output_dir"
    fitted_shot="$ARTIFACTS_DIR/$theme-fitted.png"
    magick "$shot" -alpha off -resize "${tile_width}x${tile_height}" "$fitted_shot"
    IFS='x' read -r fitted_width fitted_height <<< "$(identify -format '%wx%h' "$fitted_shot")"
    capture_x=$((tile_x + (tile_width - fitted_width) / 2))
    capture_y=$((tile_y + (tile_height - fitted_height) / 2))
    magick "$normalized_preview" \
        -fill "$background" -draw "rectangle ${tile_x},${tile_y} $((tile_x + tile_width - 1)),$((tile_y + tile_height - 1))" \
        \( "$fitted_shot" -bordercolor "$accent" -border 2 \) \
        -geometry "+${capture_x}+${capture_y}" -composite \
        -depth 8 -density 72 "PNG32:$output_dir/preview.png"

    kill -- "-$KITTY_PID" 2>/dev/null || kill "$KITTY_PID" 2>/dev/null || :
    wait "$KITTY_PID" 2>/dev/null || :
    KITTY_PID=""
done

bash "$SCRIPT_DIR/apply.sh" "${themes[@]}"
printf 'Rebuilt and applied %s preview(s).\n' "${#themes[@]}"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
if (($#)); then themes=("$@"); else printf 'Usage: %s <theme> [theme...]\n' "${0##*/}" >&2; exit 2; fi

for dependency in awk hyprctl identify jq magick omarchy grim setsid nvim btop; do
    command -v "$dependency" >/dev/null || { printf 'Required command is missing: %s\n' "$dependency" >&2; exit 1; }
done

for theme in "${themes[@]}"; do
    [[ "$theme" =~ ^[a-z0-9-]+$ ]] || { printf 'Invalid theme slug: %s\n' "$theme" >&2; exit 2; }
    [[ -r "/usr/share/omarchy/themes/$theme/colors.toml" ]] || {
        printf 'Theme colors are missing for %s\n' "$theme" >&2
        exit 1
    }
done

NVIM_PID=""
BTOP_PID=""
CAPTURE_WORKSPACE=""
ORIGINAL_THEME="$(omarchy theme current)"
ORIGINAL_WORKSPACE="$(hyprctl -j activeworkspace | jq -er '.id')"
CAPTURE_OUTPUT="$(hyprctl -j monitors | jq -er '.[] | select(.focused) | .name')"
ARTIFACTS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/omaconf-preview.XXXXXX")"
CANVAS_WIDTH=1800
CANVAS_HEIGHT=1012

stop_capture_process() {
    local pid="$1" process_status
    if ! kill -- "-$pid" 2>/dev/null && ! kill "$pid" 2>/dev/null; then
        if kill -0 "$pid" 2>/dev/null; then
            printf 'Could not stop capture window process %s\n' "$pid" >&2
            return 1
        fi
    fi
    if wait "$pid" 2>/dev/null; then
        return 0
    else
        process_status=$?
    fi
    if ((process_status != 143)); then
        printf 'Capture window process %s exited unexpectedly with status %s\n' "$pid" "$process_status" >&2
        return 1
    fi
}

focus_workspace() {
    local workspace="$1" result
    if ! result="$(hyprctl dispatch "hl.dsp.focus({ workspace = \"$workspace\" })" 2>&1)"; then
        printf 'Could not focus workspace %s: %s\n' "$workspace" "$result" >&2
        return 1
    fi
}

cleanup() {
    local status=$?
    if [[ -n "$NVIM_PID" ]] && kill -0 "$NVIM_PID" 2>/dev/null; then stop_capture_process "$NVIM_PID" || status=1; fi
    if [[ -n "$BTOP_PID" ]] && kill -0 "$BTOP_PID" 2>/dev/null; then stop_capture_process "$BTOP_PID" || status=1; fi
    if [[ -n "$CAPTURE_WORKSPACE" ]]; then
        focus_workspace "$ORIGINAL_WORKSPACE" || status=1
    fi
    if ! omarchy theme set "$ORIGINAL_THEME"; then
        printf 'Failed to restore theme %s\n' "$ORIGINAL_THEME" >&2
        status=1
    fi
    if ! rm -rf -- "$ARTIFACTS_DIR"; then
        printf 'Could not remove temporary preview directory %s\n' "$ARTIFACTS_DIR" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT INT TERM

for candidate in {90..999}; do
    if ! hyprctl -j workspaces | jq -e --argjson id "$candidate" '.[] | select(.id == $id)' >/dev/null; then
        CAPTURE_WORKSPACE="$candidate"
        break
    fi
done
[[ -n "$CAPTURE_WORKSPACE" ]] || { printf 'No free capture workspace is available.\n' >&2; exit 1; }

cat > "$ARTIFACTS_DIR/sample.lua" <<'EOF'
-- A small, readable sample for the Neovim theme preview.
local M = {}

---@param items string[]
---@return string[]
function M.sorted_unique(items)
    local seen = {}
    local result = {}
    for _, item in ipairs(items) do
        if not seen[item] then
            seen[item] = true
            result[#result + 1] = item
        end
    end
    table.sort(result)
    return result
end

return M
EOF

capture_app() {
    local app="$1" pid="$2" class="omaconf-preview-$1" client=""
    for _ in {1..100}; do
        client="$(hyprctl -j clients | jq -c --argjson pid "$pid" --arg class "$class" \
            --argjson workspace "$CAPTURE_WORKSPACE" '.[] | select(.pid == $pid and .class == $class and .workspace.id == $workspace)')"
        [[ -n "$client" ]] && break
        sleep 0.1
    done
    [[ -n "$client" ]] || { printf '%s window did not appear on workspace %s\n' "$class" "$CAPTURE_WORKSPACE" >&2; return 1; }
}

for theme in "${themes[@]}"; do
    printf 'Capturing Neovim and btop for %s\n' "$theme"
    OMARCHY_THEME_HEADLESS=1 OMARCHY_THEME_SKIP_BACKGROUND=1 omarchy theme set "$theme"
    focus_workspace "$CAPTURE_WORKSPACE"
    setsid kitty --class omaconf-preview-nvim -o font_size=9 -o window_padding_width=8 \
        -o background_opacity=1.0 -e nvim -c 'set number relativenumber cursorline termguicolors' \
        -c 'syntax on' "$ARTIFACTS_DIR/sample.lua" &
    NVIM_PID=$!
    sleep 0.5
    setsid kitty --class omaconf-preview-btop -o font_size=9 -o window_padding_width=8 \
        -o background_opacity=1.0 -e btop --filter btop &
    BTOP_PID=$!
    capture_app nvim "$NVIM_PID"
    capture_app btop "$BTOP_PID"
    sleep 3
    grim -o "$CAPTURE_OUTPUT" "$ARTIFACTS_DIR/$theme-desktop.png"
    stop_capture_process "$NVIM_PID"
    NVIM_PID=""
    stop_capture_process "$BTOP_PID"
    BTOP_PID=""
    output_dir="$SCRIPT_DIR/$theme"
    mkdir -p "$output_dir"
    magick "$ARTIFACTS_DIR/$theme-desktop.png" -resize "${CANVAS_WIDTH}x${CANVAS_HEIGHT}!" \
        -depth 8 -density 72 "PNG32:$output_dir/preview.png"
done

source "$PROJECT_DIR/scripts/lib/theme-preview.sh"
for theme in "${themes[@]}"; do
    theme_preview_normalize_file "$SCRIPT_DIR/$theme/preview.png" || exit 1
done
bash "$SCRIPT_DIR/apply.sh" "${themes[@]}"
printf 'Rebuilt and applied %s preview(s).\n' "${#themes[@]}"

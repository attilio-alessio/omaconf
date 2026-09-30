THEME_PREVIEW_CANVAS="${THEME_PREVIEW_CANVAS:-1800x1012}"
THEME_PREVIEW_BACKUP_DIR="${THEME_PREVIEW_BACKUP_DIR:-/var/cache/omaconf/theme-preview-stock}"
THEME_PREVIEW_OVERLAY_STORE="${THEME_PREVIEW_OVERLAY_STORE:-/var/lib/omaconf/theme-preview-overlay}"
THEME_PREVIEW_DENSITY="${THEME_PREVIEW_DENSITY:-72}"
THEME_PREVIEW_DEPTH="${THEME_PREVIEW_DEPTH:-8}"

theme_preview_uniform() {
    local preview="$1" type
    [[ "$(identify -format '%wx%h' "$preview" 2>/dev/null)" == "$THEME_PREVIEW_CANVAS" ]] || return 1
    type="$(identify -format '%[type]' "$preview" 2>/dev/null)"
    [[ "$type" == *Alpha ]] || return 1
    [[ "$(identify -format '%z' "$preview" 2>/dev/null)" == "$THEME_PREVIEW_DEPTH" ]] || return 1
    [[ "$(identify -format '%x' "$preview" 2>/dev/null)" == "$THEME_PREVIEW_DENSITY" ]] || return 1
    return 0
}

theme_preview_normalize_file() {
    local preview="$1" tmp
    theme_preview_uniform "$preview" && return 0
    tmp="$preview.tmp.$$"
    if magick "$preview" -resize "${THEME_PREVIEW_CANVAS}!" -depth "$THEME_PREVIEW_DEPTH" \
        -density "$THEME_PREVIEW_DENSITY" "PNG32:$tmp" 2>/dev/null &&
        install -m 644 "$tmp" "$preview" 2>/dev/null; then
        rm -f "$tmp"
        return 0
    fi
    rm -f "$tmp"
    warn "theming.preview_resize_failed" "$preview"
    return 1
}

theme_preview_store_overlay() {
    local src="$1" theme="$2" staged
    [[ -f "$src" ]] || return 1
    mkdir -p "$THEME_PREVIEW_OVERLAY_STORE" 2>/dev/null || return 1
    staged="$THEME_PREVIEW_OVERLAY_STORE/.$theme.png.$$"
    cp "$src" "$staged" 2>/dev/null || return 1
    if theme_preview_normalize_file "$staged"; then
        mv -f "$staged" "$THEME_PREVIEW_OVERLAY_STORE/$theme.png"
        return $?
    fi
    rm -f "$staged"
    return 1
}

theme_preview_restore_overlays() {
    local themes_root="$1" stored target owner=()
    [[ -d "$THEME_PREVIEW_OVERLAY_STORE" ]] || return 0
    if [[ "$(id -u)" -eq 0 ]]; then owner=(-o root -g root); fi
    for stored in "$THEME_PREVIEW_OVERLAY_STORE"/*.png; do
        [[ -f "$stored" ]] || continue
        target="$themes_root/$(basename "$stored" .png)/preview.png"
        [[ -f "$target" ]] || continue
        cmp -s "$stored" "$target" 2>/dev/null && continue
        if install -m 644 "${owner[@]}" "$stored" "$target" 2>/dev/null; then
            log "theming.preview_overlay_restored" "$(basename "$stored" .png)"
        else
            warn "theming.preview_resize_failed" "$target"
        fi
    done
}

theme_preview_normalize() {
    command -v magick >/dev/null || return 0
    command -v identify >/dev/null || return 0
    local themes_root="${THEME_PREVIEW_THEMES_ROOT:-/usr/share/omarchy/themes}"
    [[ -d "$themes_root" ]] || return 0
    local backup_dir preview size original
    backup_dir="$THEME_PREVIEW_BACKUP_DIR"
    for preview in "$themes_root"/*/preview.png; do
        [[ -f "$preview" ]] || continue
        theme_preview_uniform "$preview" && continue
        size="$(identify -format '%wx%h' "$preview" 2>/dev/null)" || continue
        if [[ "$size" != "$THEME_PREVIEW_CANVAS" ]]; then
            if ! mkdir -p "$backup_dir" 2>/dev/null; then
                warn "theming.preview_backup_failed" "$backup_dir"
                return 1
            fi
            original="$backup_dir/$(basename "$(dirname "$preview")")-$size.png"
            if [[ ! -f "$original" ]] && ! cp -a "$preview" "$original" 2>/dev/null; then
                warn "theming.preview_backup_failed" "$original"
                return 1
            fi
        fi
        theme_preview_normalize_file "$preview" || return 1
    done
    theme_preview_restore_overlays "$themes_root"
}

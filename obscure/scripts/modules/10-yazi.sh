#!/bin/bash
set -euo pipefail

MARK_BEGIN="# >>> omaconf obscure >>>"
MARK_END="# <<< omaconf obscure <<<"
PATTERNS_FILE="$PROJECT_DIR/data/patterns"
PLUGIN_SRC="$PROJECT_DIR/data/obscure.yazi"

[[ -f "$PATTERNS_FILE" ]] || { warn "patterns file missing"; return 0; }

mapfile -t PATTERNS < <(grep -vE '^\s*(#|$)' "$PATTERNS_FILE" 2>/dev/null || :)

insert_after_header() {
    local file="$1" header="$2" block="$3"
    local tmp=""
    tmp=$(mktemp) || { warn "tmpfile failed for $file"; return 1; }
    awk -v header="$header" -v block="$block" '
        BEGIN { done = 0 }
        {
            print $0
            if (!done && $0 == header) {
                print block
                done = 1
            }
        }
        END { if (!done) { print header; print block } }
    ' "$file" > "$tmp" && cat "$tmp" > "$file"
    rm -f "$tmp"
}

build_previewer_block() {
    printf '%s\n' "$MARK_BEGIN"
    printf '%s\n' "[plugin]"
    printf '%s\n' "prepend_previewers = ["
    local pat=""
    for pat in "${PATTERNS[@]}"; do
        printf '\t{ url = "%s", run = "obscure" },\n' "$pat"
    done
    printf '%s\n' "]"
    printf '%s\n' "$MARK_END"
}

build_icon_block() {
    printf '%s\n' "$MARK_BEGIN"
    printf '%s\n' "prepend_globs = ["
    local pat=""
    for pat in "${PATTERNS[@]}"; do
        printf '\t{ url = "%s", text = "", fg = "red" },\n' "$pat"
    done
    printf '%s\n' "]"
    printf '%s\n' "$MARK_END"
}

build_open_block() {
    printf '%s\n' "$MARK_BEGIN"
    printf '%s\n' "prepend_rules = ["
    local pat=""
    for pat in "${PATTERNS[@]}"; do
        printf '\t{ url = "%s", use = "obscure-view" },\n' "$pat"
    done
    printf '%s\n' "]"
    printf '%s\n' "$MARK_END"
}

build_opener_block() {
    printf '%s\n' "$MARK_BEGIN"
    printf '%s\n' 'obscure-view = [ { run = "obscure-view %s", desc = "Unlock with obscure password", block = true, for = "unix" }, ]'
    printf '%s\n' "$MARK_END"
}

log "Installing obscure helpers"
install -m 755 "$PROJECT_DIR/bin/obscure-view" /usr/local/bin/obscure-view 2>/dev/null || warn "obscure-view install skipped"

log "Installing obscure yazi gate per user"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    _u=$(basename "$u_home")
    _config="$u_home/.config"
    _yazi="$_config/yazi"
    _plugin="$_yazi/plugins/obscure.yazi"
    _obscure="$_config/obscure"
    mkdir -p "$_yazi/plugins" "$_obscure" 2>/dev/null || { warn "config dirs skipped for $_u"; continue; }

    rm -rf "$_plugin" 2>/dev/null || warn "plugin refresh skipped for $_u"
    cp -a "$PLUGIN_SRC" "$_plugin" 2>/dev/null || warn "plugin install skipped for $_u"
    cp "$PATTERNS_FILE" "$_obscure/patterns" 2>/dev/null || warn "patterns install skipped for $_u"

    _toml="$_yazi/yazi.toml"
    [[ -f "$_toml" ]] || printf '%s\n' "[mgr]" > "$_toml" 2>/dev/null || { warn "yazi.toml create skipped for $_u"; continue; }
    if ! grep -qF 'run = "obscure"' "$_toml" 2>/dev/null; then
        if grep -qE '^\[plugin\]' "$_toml" 2>/dev/null; then
            insert_after_header "$_toml" "[plugin]" "$(build_previewer_block)" 2>/dev/null || warn "previewer block skipped for $_u"
        else
            { printf '%s\n' "[plugin]"; build_previewer_block; } >> "$_toml" 2>/dev/null || warn "previewer block skipped for $_u"
        fi
    fi
    if ! grep -qF 'obscure-view = [' "$_toml" 2>/dev/null; then
        if grep -qE '^\[opener\]' "$_toml" 2>/dev/null; then
            insert_after_header "$_toml" "[opener]" "$(build_opener_block)" 2>/dev/null || warn "opener insert skipped for $_u"
        else
            { printf '%s\n' "[opener]"; build_opener_block; } >> "$_toml" 2>/dev/null || warn "opener block skipped for $_u"
        fi
    fi
    if ! grep -qF 'use = "obscure-view"' "$_toml" 2>/dev/null; then
        if grep -qE '^\[open\]' "$_toml" 2>/dev/null; then
            insert_after_header "$_toml" "[open]" "$(build_open_block)" 2>/dev/null || warn "open rules insert skipped for $_u"
        else
            { printf '%s\n' "[open]"; build_open_block; } >> "$_toml" 2>/dev/null || warn "open block skipped for $_u"
        fi
    fi

    _theme="$_yazi/theme.toml"
    [[ -f "$_theme" ]] || printf '%s\n' "[manager]" > "$_theme" 2>/dev/null || { warn "theme.toml create skipped for $_u"; continue; }
    if ! grep -qF "$MARK_BEGIN" "$_theme" 2>/dev/null; then
        if grep -qE '^\[icon\]' "$_theme" 2>/dev/null; then
            insert_after_header "$_theme" "[icon]" "$(build_icon_block)" 2>/dev/null || warn "icon rules skipped for $_u"
        else
            { printf '%s\n' "[icon]"; build_icon_block; } >> "$_theme" 2>/dev/null || warn "icon block skipped for $_u"
        fi
    fi

    chown -R "$_u":"$_u" "$_yazi" "$_obscure" 2>/dev/null || warn "chown skipped for $_u"
done

#!/usr/bin/env bash

install_user_file() {
    local src="$1" dest="$2" mode="${3:-644}"
    [[ -f "$src" ]] || return 0
    mkdir -p "$(dirname "$dest")" || return 1
    if [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            chmod "$mode" "$dest"
            return 0
        fi
        cp "$dest" "$dest.bak"
    fi
    install -m "$mode" "$src" "$dest"
}

install_user_content() {
    local dest="$1" mode="${2:-644}" tmp
    mkdir -p "$(dirname "$dest")" || return 1
    tmp="$(mktemp "$dest.tmp.XXXXXX")" || return 1
    cat > "$tmp"
    if [[ -f "$dest" ]]; then
        if cmp -s "$tmp" "$dest"; then
            rm -f "$tmp"
            chmod "$mode" "$dest"
            return 0
        fi
        cp "$dest" "$dest.bak"
    fi
    chmod "$mode" "$tmp"
    mv "$tmp" "$dest"
}

install_shell_block() {
    local rc="$1" begin="$2" end="$3" block
    [[ -f "$rc" ]] || return 0
    block="$(cat)"
    local staged
    staged="$(mktemp)" || return 1
    awk -v begin="$begin" -v end="$end" '
        index($0, begin) { skip = 1; next }
        skip && index($0, end) { skip = 0; next }
        skip { next }
        { body[++kept] = $0 }
        END {
            last = kept
            while (last > 0 && body[last] ~ /^[[:space:]]*$/) last--
            for (i = 1; i <= last; i++) print body[i]
        }
    ' "$rc" > "$staged"
    if [[ -s "$staged" ]]; then
        printf '\n' >> "$staged"
    fi
    printf '%s\n%s\n%s\n' "$begin" "$block" "$end" >> "$staged"
    if ! cmp -s "$staged" "$rc"; then
        cat "$staged" > "$rc"
    fi
    rm -f "$staged"
}
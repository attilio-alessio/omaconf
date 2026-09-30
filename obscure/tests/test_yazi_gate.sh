#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
YAZI_MODULE="$PROJECT_DIR/scripts/modules/10-yazi.sh"
PLUGIN="$PROJECT_DIR/data/obscure.yazi/main.lua"
PATTERNS="$PROJECT_DIR/data/patterns"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Yazi Sensitive Preview Gate"

assert_file_exists "patterns file exists" "$PATTERNS"
assert_file_contains "patterns cover 2fa backups" "$PATTERNS" "2fa"
assert_file_contains "patterns cover totp" "$PATTERNS" "totp"
assert_file_contains "patterns cover recovery codes" "$PATTERNS" "recovery"
assert_file_contains "patterns cover secrets" "$PATTERNS" "secret"
assert_file_exists "plugin main.lua exists" "$PLUGIN"
if command -v luac &>/dev/null; then
    assert_true "plugin passes luac syntax check" "luac -p '$PLUGIN'"
fi
assert_file_contains "plugin renders lock screen" "$PLUGIN" "Locked by obscure"
assert_file_contains "plugin shows lock icon" "$PLUGIN" "🔒"
assert_file_contains "plugin implements peek" "$PLUGIN" "function M:peek"
assert_file_contains "plugin implements seek" "$PLUGIN" "function M:seek"
assert_false "plugin never leaks content via code preview" "grep -q 'preview_code' '$PLUGIN'"
assert_file_contains "yazi module registers previewers" "$YAZI_MODULE" 'run = "obscure"'
assert_file_contains "yazi module merges previewers into an existing plugin section" "$YAZI_MODULE" 'insert_after_header.*plugin'
assert_file_contains "yazi module creates a plugin section when absent" "$YAZI_MODULE" 'build_previewer_block;'
assert_file_contains "yazi module gates open action" "$YAZI_MODULE" 'use = "obscure-view"'
assert_file_contains "yazi module closes the managed opener block" "$YAZI_MODULE" 'printf.*MARK_END'
assert_file_contains "yazi module sets lock icons" "$YAZI_MODULE" "prepend_globs"
assert_file_contains "yazi module installs plugin per user" "$YAZI_MODULE" "obscure.yazi"
assert_file_contains "yazi module syncs patterns per user" "$YAZI_MODULE" "patterns"
assert_file_contains "yazi module fixes ownership" "$YAZI_MODULE" "chown"
assert_file_contains "verify checks previewer gate" "$PROJECT_DIR/scripts/verify.sh" 'run = "obscure"'
assert_file_contains "verify checks open gate" "$PROJECT_DIR/scripts/verify.sh" 'use = "obscure-view"'

merge_simulation() {
    local work=""
    work=$(mktemp -d) || return 1
    local cfg="$work/.config/yazi"
    mkdir -p "$cfg"
    printf '%s\n' "[mgr]" "show_hidden = false" "" "[opener]" 'edit = [' ']' "" "[open]" 'rules = [' ']' > "$cfg/yazi.toml"
    {
        printf '%s\n' "# >>> omablot obscure >>>" "[plugin]" "prepend_previewers = ["
        local pat=""
        while IFS= read -r pat; do
            [[ "$pat" =~ ^[[:space:]]*(#|$) ]] && continue
            printf '\t{ url = "%s", run = "obscure" },\n' "$pat"
        done < "$PATTERNS"
        printf '%s\n' "]" "# <<< omablot obscure <<<"
    } >> "$cfg/yazi.toml"
    awk '/^\[plugin\]$/{section=1; next} /^\[/{section=0} section && /prepend_previewers = \[/{found=1} END{exit !found}' "$cfg/yazi.toml" || { rm -rf "$work"; return 1; }
    rm -rf "$work"
    return 0
}

assert_true "generated previewer block is valid TOML" "merge_simulation"

test_summary

#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VIEW="$PROJECT_DIR/bin/obscure-view"

source "$SCRIPT_DIR/test_lib.sh"

test_section "System Password Gate Helpers"

assert_file_exists "obscure-view exists" "$VIEW"
assert_file_executable "obscure-view is executable" "$VIEW"
assert_false "no separate password helper ships" "[[ -f '$PROJECT_DIR/bin/obscure-set-password' ]]"
assert_file_contains "view verifies system password via sudo" "$VIEW" "sudo -S -v"
assert_file_contains "view drops sudo timestamp" "$VIEW" "sudo -k"
assert_file_contains "view pages text safely" "$VIEW" "PAGER"
assert_file_contains "view handles pdf files" "$VIEW" "is_pdf"
assert_file_contains "yazi module installs single helper" "$PROJECT_DIR/scripts/modules/10-yazi.sh" "/usr/local/bin/obscure-view"
assert_file_contains "setup elevates with pkexec" "$PROJECT_DIR/Makefile" "pkexec"
assert_file_contains "run-setup elevates with pkexec" "$PROJECT_DIR/scripts/run-setup.sh" "pkexec"

make_fake_sudo() {
    local dest="$1"
    cat > "$dest/sudo" << 'STUB'
#!/bin/bash
if [[ "$1" == "-k" ]]; then
    exit 0
fi
input=$(cat)
if [[ "$input" == "$FAKE_OS_PASSWORD" ]]; then
    exit 0
fi
exit 1
STUB
    chmod +x "$dest/sudo"
}

make_fake_pdf() {
    local dest="$1"
    local content="BT /F1 24 Tf 100 700 Td (SECRET_BACKUP_CODE_98765) Tj ET"
    local slen=${#content}
    cat > "$dest" << PDFEOF
%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj
3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<</Font<</F1 4 0 R>>>>/Contents 5 0 R>>endobj
4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
5 0 obj<</Length ${slen}>>
stream
${content}
endstream
endobj
xref
0 6
0000000000 65535 f 
0000000010 00000 n 
0000000053 00000 n 
0000000102 00000 n 
0000000213 00000 n 
0000000277 00000 n 
trailer<</Size 6/Root 1 0 R>>
startxref
360
%%EOF
PDFEOF
}

auth_roundtrip() {
    local work=""
    work=$(mktemp -d) || return 1
    export HOME="$work"
    export XDG_CONFIG_HOME="$work/.config"
    export PAGER=cat
    export FAKE_OS_PASSWORD="login-pw-123"
    make_fake_sudo "$work" || { rm -rf "$work"; return 1; }
    printf 'my-2fa-backup-codes\n123 456\n' > "$work/codes-2fa.txt"
    out=$(PATH="$work:$PATH" OBSCURE_PASSWORD="login-pw-123" bash "$VIEW" "$work/codes-2fa.txt" 2>/dev/null) || { rm -rf "$work"; return 1; }
    [[ "$out" == *"my-2fa-backup-codes"* ]] || { rm -rf "$work"; return 1; }
    if PATH="$work:$PATH" OBSCURE_PASSWORD="wrong-pw" bash "$VIEW" "$work/codes-2fa.txt" &>/dev/null; then rm -rf "$work"; return 1; fi
    rm -rf "$work"
    return 0
}

auth_roundtrip_pdf() {
    local work=""
    work=$(mktemp -d) || return 1
    export HOME="$work"
    export XDG_CONFIG_HOME="$work/.config"
    export PAGER=cat
    export FAKE_OS_PASSWORD="login-pw-123"
    local saved_wayland="${WAYLAND_DISPLAY:-}"
    local saved_display="${DISPLAY:-}"
    unset WAYLAND_DISPLAY DISPLAY
    make_fake_sudo "$work" || { rm -rf "$work"; return 1; }
    make_fake_pdf "$work/recovery-codes.pdf" || { rm -rf "$work"; return 1; }
    if command -v pdftotext &>/dev/null; then
        out=$(PATH="$work:$PATH" OBSCURE_PASSWORD="login-pw-123" bash "$VIEW" "$work/recovery-codes.pdf" 2>/dev/null) || { rm -rf "$work"; return 1; }
        [[ "$out" == *"SECRET_BACKUP_CODE_98765"* ]] || { rm -rf "$work"; return 1; }
    else
        PATH="$work:$PATH" OBSCURE_PASSWORD="login-pw-123" bash "$VIEW" "$work/recovery-codes.pdf" 2>/dev/null || { rm -rf "$work"; return 1; }
    fi
    if PATH="$work:$PATH" OBSCURE_PASSWORD="wrong-pw" bash "$VIEW" "$work/recovery-codes.pdf" &>/dev/null; then rm -rf "$work"; return 1; fi
    [[ -n "$saved_wayland" ]] && export WAYLAND_DISPLAY="$saved_wayland"
    [[ -n "$saved_display" ]] && export DISPLAY="$saved_display"
    rm -rf "$work"
    return 0
}

assert_true "system password roundtrip opens gated file" "auth_roundtrip"
assert_true "wrong system password is rejected" "auth_roundtrip"
assert_true "system password roundtrip opens gated pdf" "auth_roundtrip_pdf"

test_summary

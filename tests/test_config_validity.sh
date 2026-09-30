#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SHELL_PLUGINS_MODULE="$PROJECT_DIR/scripts/modules/35-shell-plugins.sh"
YAZI_DATA="$PROJECT_DIR/yaziconf/data"
CLICONF_DATA="$PROJECT_DIR/cliconf/data"
NVIM_DATA="$PROJECT_DIR/nvimconf/data"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Config Validity & Placement Regression"

assert_file_contains "shell plugins module keeps omamp on the right" "$SHELL_PLUGINS_MODULE" "section right"

if command -v python3 &>/dev/null; then
    assert_true "yazi.toml parses as TOML" "python3 -c \"import tomllib; tomllib.load(open('$YAZI_DATA/yazi.toml','rb'))\""
    assert_true "yazi theme.toml parses as TOML" "python3 -c \"import tomllib; tomllib.load(open('$YAZI_DATA/theme.toml','rb'))\""
    assert_true "every yazi open rule has url or mime" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$YAZI_DATA/yazi.toml','rb'))
rules = cfg.get('open', {}).get('rules', [])
assert rules, 'no open rules found'
bad = [r for r in rules if 'url' not in r and 'mime' not in r]
assert not bad, f'rules without url/mime: {bad}'
\""
    assert_true "every yazi opener has a run command" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$YAZI_DATA/yazi.toml','rb'))
ops = cfg.get('opener', {})
assert ops, 'no openers found'
bad = [k for k, v in ops.items() if not all('run' in e for e in v)]
assert not bad, f'openers without run: {bad}'
\""
else
    assert_true "python3 available for TOML checks" "false"
fi

if command -v luac &>/dev/null; then
    assert_true "nvim helpers lua syntax valid" "luac -p '$NVIM_DATA/omaconf-helpers.lua'"
    assert_true "nvim completion lua syntax valid" "luac -p '$NVIM_DATA/omaconf-completion.lua'"
fi

assert_true "cliconf helpers bash syntax valid" "bash -n '$CLICONF_DATA/helpers.sh'"
assert_true "cliconf installer bash syntax valid" "bash -n '$PROJECT_DIR/cliconf/install.sh'"

for tool in mpv zathura imv fzf rg fd bat eza zoxide git lazygit gum ai; do
    assert_file_contains "cliconf covers $tool" "$CLICONF_DATA/helpers.sh" "$tool)"
done

if command -v desktop-file-validate &>/dev/null; then
    assert_true "yazi-terminal desktop file valid" "desktop-file-validate '$YAZI_DATA/yazi-terminal.desktop'"
else
    assert_file_contains "yazi-terminal desktop has Exec" "$YAZI_DATA/yazi-terminal.desktop" "^Exec="
    assert_file_contains "yazi-terminal desktop handles directories" "$YAZI_DATA/yazi-terminal.desktop" "inode/directory"
fi

USERCONF_LIB="$PROJECT_DIR/scripts/lib/userconf.sh"
assert_file_exists "user config library exists" "$USERCONF_LIB"
assert_file_contains "user config library installs files from a source" "$USERCONF_LIB" "^install_user_file\(\)"
assert_file_contains "user config library installs content from stdin" "$USERCONF_LIB" "^install_user_content\(\)"
assert_file_contains "user config library manages shell blocks" "$USERCONF_LIB" "^install_shell_block\(\)"
assert_true "user config library leaves caller shell options untouched" \
    "bash -c 'set +e +u; source \"$USERCONF_LIB\"; [[ \$- != *e* && \$- != *u* ]]'"
assert_true "no installer keeps the ad hoc timestamped backup" \
    "! grep -qE 'bak-\\\$\\(date' '$PROJECT_DIR'/*conf/install.sh"

for installer in cliconf microconf nvimconf yaziconf zedconf; do
    assert_file_contains "$installer sources the user config library" \
        "$PROJECT_DIR/$installer/install.sh" "userconf.sh"
done

if ((UID != 0)); then
    USERCONF_SANDBOX="$(mktemp -d)"
    mkdir -p "$USERCONF_SANDBOX/src" "$USERCONF_SANDBOX/dst"
    printf 'first\n' > "$USERCONF_SANDBOX/src/payload"
    printf 'stale\n' > "$USERCONF_SANDBOX/dst/payload"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_user_file "$USERCONF_SANDBOX/src/payload" "$USERCONF_SANDBOX/dst/payload"
    ) 2>/dev/null
    assert_true "user config library installs the new content" \
        "grep -q '^first$' '$USERCONF_SANDBOX/dst/payload'"
    assert_true "user config library keeps the replaced content in a single slot backup" \
        "[[ -f '$USERCONF_SANDBOX/dst/payload.bak' ]] && ! ls '$USERCONF_SANDBOX/dst/' | grep -qE '\.bak-'"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_user_file "$USERCONF_SANDBOX/src/payload" "$USERCONF_SANDBOX/dst/payload"
        install_user_file "$USERCONF_SANDBOX/src/payload" "$USERCONF_SANDBOX/dst/payload"
    ) 2>/dev/null
    assert_true "user config library never accumulates backups across runs" \
        "[[ \$(ls -1 '$USERCONF_SANDBOX/dst/' | grep -c 'payload') -eq 2 ]]"

    printf '# rc\n\n# >>> omaconf sandbox >>>\nold() { :; }\n# <<< omaconf sandbox <<<\n' > "$USERCONF_SANDBOX/rc"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_shell_block "$USERCONF_SANDBOX/rc" "# >>> omaconf sandbox >>>" "# <<< omaconf sandbox <<<" << 'BLOCK'
new() { :; }
BLOCK
    ) 2>/dev/null
    assert_true "shell block replaces the previous marked range" \
        "! grep -q 'old()' '$USERCONF_SANDBOX/rc'"
    assert_true "shell block writes the new body" \
        "grep -q 'new()' '$USERCONF_SANDBOX/rc'"
    assert_true "shell block writes exactly one marked range" \
        "[[ \$(grep -c '>>> omaconf sandbox >>>' '$USERCONF_SANDBOX/rc') -eq 1 ]]"

    printf '# rc\n\n# >>> omaconf sandbox >>>\nnew() { :; }\n# <<< omaconf sandbox <<<\n' > "$USERCONF_SANDBOX/rc-idem"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_shell_block "$USERCONF_SANDBOX/rc-idem" "# >>> omaconf sandbox >>>" "# <<< omaconf sandbox <<<" << 'BLOCK'
new() { :; }
BLOCK
    ) 2>/dev/null
    assert_true "shell block is idempotent" \
        "cmp -s '$USERCONF_SANDBOX/rc' '$USERCONF_SANDBOX/rc-idem'"
    rm -rf "$USERCONF_SANDBOX"
fi

test_summary

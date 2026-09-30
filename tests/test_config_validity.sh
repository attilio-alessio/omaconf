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
    assert_true "nvim helpers lua syntax valid" "luac -p '$NVIM_DATA/omablot-helpers.lua'"
    assert_true "nvim completion lua syntax valid" "luac -p '$NVIM_DATA/omablot-completion.lua'"
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

test_summary

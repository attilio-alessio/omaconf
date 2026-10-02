#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Script Syntax & Code Integrity"

for sh_file in "$PROJECT_DIR"/scripts/*.sh "$PROJECT_DIR"/scripts/lib/*.sh "$PROJECT_DIR"/scripts/modules/*.sh "$PROJECT_DIR"/hooks/theme-set.d/* "$PROJECT_DIR"/hooks/pre-refresh-pacman.d/* "$PROJECT_DIR"/hooks/post-update.d/* "$PROJECT_DIR"/zedconf/*.sh "$PROJECT_DIR"/microconf/*.sh "$PROJECT_DIR"/nvimconf/*.sh "$PROJECT_DIR"/yaziconf/*.sh "$PROJECT_DIR"/cliconf/*.sh "$PROJECT_DIR"/herdrconf/*.sh "$PROJECT_DIR"/tests/*.sh; do
    [[ -f "$sh_file" ]] || continue
    fname=$(basename "$sh_file")
    assert_true "syntax check: $fname" "bash -n '$sh_file'"
done

assert_true "syntax check: herdr-keybindings-menu" "bash -n '$PROJECT_DIR/herdrconf/data/herdr-keybindings-menu'"

assert_file_executable "scripts/setup.sh is executable" "$PROJECT_DIR/scripts/setup.sh"
assert_file_executable "scripts/verify.sh is executable" "$PROJECT_DIR/scripts/verify.sh"
assert_file_executable "scripts/launch.sh is executable" "$PROJECT_DIR/scripts/launch.sh"
assert_file_executable "scripts/run-setup.sh is executable" "$PROJECT_DIR/scripts/run-setup.sh"
assert_file_executable "hooks/theme-set.d/folder-color is executable" "$PROJECT_DIR/hooks/theme-set.d/folder-color"
assert_file_executable "hooks/theme-set.d/micro-theme is executable" "$PROJECT_DIR/hooks/theme-set.d/micro-theme"
assert_file_executable "hooks/pre-refresh-pacman.d/99-omaconf-persist is executable" "$PROJECT_DIR/hooks/pre-refresh-pacman.d/99-omaconf-persist"
assert_file_executable "hooks/post-update.d/99-omaconf-persist is executable" "$PROJECT_DIR/hooks/post-update.d/99-omaconf-persist"
assert_file_executable "zedconf/install.sh is executable" "$PROJECT_DIR/zedconf/install.sh"
assert_file_executable "microconf/install.sh is executable" "$PROJECT_DIR/microconf/install.sh"
assert_file_executable "yaziconf/install.sh is executable" "$PROJECT_DIR/yaziconf/install.sh"
assert_file_executable "herdrconf/install.sh is executable" "$PROJECT_DIR/herdrconf/install.sh"
assert_file_executable "herdr-keybindings-menu is executable" "$PROJECT_DIR/herdrconf/data/herdr-keybindings-menu"

for mod in "$PROJECT_DIR"/scripts/modules/*.sh; do
    [[ -f "$mod" ]] || continue
    mname=$(basename "$mod")
    assert_file_executable "module $mname is executable" "$mod"
    assert_file_contains "module $mname uses strict mode" "$mod" "set -euo pipefail"
done

assert_file_executable "scripts/lib/i18n.sh is executable" "$PROJECT_DIR/scripts/lib/i18n.sh"
assert_file_executable "scripts/lib/help.sh is executable" "$PROJECT_DIR/scripts/lib/help.sh"
assert_true "i18n.sh does not alter caller shell options" "bash -c 'set +e +u; source \"$PROJECT_DIR/scripts/lib/i18n.sh\"; [[ \$- != *e* && \$- != *u* ]]'"
assert_true "locale-map.sh does not alter caller shell options" "bash -c 'set +e +u; source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \$- != *e* && \$- != *u* ]]'"
assert_file_contains "help.sh uses strict mode" "$PROJECT_DIR/scripts/lib/help.sh" "set -euo pipefail"
assert_file_contains "setup.sh uses strict mode" "$PROJECT_DIR/scripts/setup.sh" "set -euo pipefail"
assert_file_contains "verify.sh uses strict mode" "$PROJECT_DIR/scripts/verify.sh" "set -uo pipefail"
assert_file_contains "launch.sh uses strict mode" "$PROJECT_DIR/scripts/launch.sh" "set -euo pipefail"
assert_file_contains "run-setup.sh uses strict mode" "$PROJECT_DIR/scripts/run-setup.sh" "set -euo pipefail"
assert_file_contains "folder-color uses strict mode" "$PROJECT_DIR/hooks/theme-set.d/folder-color" "set -euo pipefail"
assert_file_contains "micro-theme uses strict mode" "$PROJECT_DIR/hooks/theme-set.d/micro-theme" "set -euo pipefail"
assert_file_contains "pre-refresh persist hook uses strict mode" "$PROJECT_DIR/hooks/pre-refresh-pacman.d/99-omaconf-persist" "set -euo pipefail"
assert_file_contains "post-update persist hook uses strict mode" "$PROJECT_DIR/hooks/post-update.d/99-omaconf-persist" "set -euo pipefail"

test_summary

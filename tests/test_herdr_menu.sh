#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HERDR_MENU="$PROJECT_DIR/herdrconf/data/herdr-keybindings-menu"
HERDR_INSTALLER="$PROJECT_DIR/herdrconf/install.sh"
MSG_DIR="$PROJECT_DIR/scripts/lib/messages"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Herdr Click-to-Run Keybindings Menu"

SB="$(mktemp -d)"
trap 'rm -rf "$SB"' EXIT
mkdir -p "$SB/fakebin" "$SB/home/.config/hypr" "$SB/home/.local/share"

FAKE_ADDR="0xHERDRTEST"

cat > "$SB/default.toml" << 'EOF'
[keys]
# prefix = "ctrl+b"
# help = "prefix+?"
# settings = "prefix+s"
# detach = "prefix+q"
# new_tab = "prefix+c"
# close_pane = "prefix+x"
# split_horizontal = ["prefix+h", "alt+enter"]
# switch_tab = ["prefix+1..9", "alt+1..9"]
# focus_pane_left = "prefix+h"
# workspace_picker = "prefix+w"
# navigate_pane_left = "h"
# navigate_workspace_up = "up"
# unbound_action = ""
# type = "popup" opens a session-modal terminal
# [[keys.command]]
# key = "prefix+alt+g"
EOF

cat > "$SB/user.toml" << 'EOF'
[keys]
prefix = "ctrl+space"
new_tab = "prefix+t"
close_pane = ""
EOF

cat > "$SB/noprefix.toml" << 'EOF'
[keys]
new_tab = "prefix+c"
EOF

cat > "$SB/empty.toml" << 'EOF'
# empty user configuration
EOF

cat > "$SB/fakebin/herdr" << 'EOF'
#!/bin/bash
if [[ "${1:-}" == "--default-config" ]]; then
    if [[ "${HERDR_FAKE_EMPTY:-0}" == "1" ]]; then
        exit 0
    fi
    cat "@SB@/default.toml"
    exit 0
fi
if [[ "${1:-}" == "status" ]]; then
    if [[ "${HERDR_FAKE_RUNNING:-1}" == "1" ]]; then
        printf '{"status":"running","running":true}'
    else
        printf '{"status":"stopped","running":false}'
    fi
    exit 0
fi
exit 0
EOF

cat > "$SB/fakebin/hyprctl" << 'EOF'
#!/bin/bash
printf 'HYPRCTL: %s\n' "$*" >> "@SB@/hyprctl.log"
if [[ "${1:-}" == "clients" ]]; then
    cat "@SB@/clients.json"
    exit 0
fi
if [[ "${1:-}" == "monitors" ]]; then
    printf '[{"focused":true,"height":1080}]'
    exit 0
fi
exit 0
EOF

cat > "$SB/fakebin/jq" << 'EOF'
#!/bin/bash
filter="${*: -1}"
if [[ "$filter" == *"height"* ]]; then
    printf '1080'
    exit 0
fi
if [[ "$filter" == *".pid"* ]]; then
    printf '%s %s\n' "@SB_ADDR@" "${HERDR_FAKE_CPID:-424242}"
    exit 0
fi
if [[ "$filter" == *"address"* ]]; then
    if [[ "${HERDR_FAKE_NAME_MATCH:-1}" == "1" ]]; then
        printf '%s\n' "@SB_ADDR@"
    fi
    exit 0
fi
exit 0
EOF

cat > "$SB/fakebin/wtype" << 'EOF'
#!/bin/bash
printf '<%s>' "$@" >> "@SB@/wtype.log"
printf '\n' >> "@SB@/wtype.log"
exit 0
EOF

cat > "$SB/fakebin/omarchy-menu-select" << 'EOF'
#!/bin/bash
if [[ "${HERDR_FAKE_SELECT_MODE:-}" == "cancel" ]]; then
    exit 1
fi
printf '%s\n' "${HERDR_FAKE_SELECTION:-}"
exit 0
EOF

cat > "$SB/fakebin/pgrep" << 'EOF'
#!/bin/bash
if [[ "${1:-}" == "-x" && "${2:-}" == "herdr" ]]; then
    if [[ -n "${HERDR_FAKE_PIDS:-}" ]]; then
        # shellcheck disable=SC2086
        printf '%s\n' $HERDR_FAKE_PIDS
        exit 0
    fi
    exit 1
fi
exit 1
EOF

chmod +x "$SB"/fakebin/*
sed -i "s|@SB@|$SB|g" "$SB"/fakebin/*
sed -i "s|@SB_ADDR@|$FAKE_ADDR|g" "$SB"/fakebin/jq

printf '[{"address":"%s","pid":424242,"class":"kitty","title":"host: work","initialClass":"","initialTitle":"herdr"}]' "$FAKE_ADDR" > "$SB/clients.json"

menu_lib() (
    grep -qF 'if [[ "$print_only" == "true" ]]; then' "$HERDR_MENU" || return 1
    sed -n '1,/^if \[\[ "\${BASH_SOURCE\[0\]:-}" == "\$0" \]\]; then$/p' "$HERDR_MENU" | head -n -1 > "$SB/menu-lib.sh"
    bash -n "$SB/menu-lib.sh"
)

fake_env() {
    export PATH="$SB/fakebin:$PATH"
    export HERDR_CONFIG_PATH="$SB/user.toml"
    export HERDR_FAKE_RUNNING=1 HERDR_FAKE_NAME_MATCH=1 HERDR_FAKE_EMPTY=0
    export HERDR_FAKE_SELECT_MODE="" HERDR_FAKE_SELECTION=""
}

gen_records() (
    fake_env
    # shellcheck source=/dev/null
    source "$SB/menu-lib.sh"
    set +e
    output_records > "$SB/records.txt" 2>/dev/null
)

test_section "Menu Structure & Conventions"

assert_file_exists "herdr menu script exists" "$HERDR_MENU"
assert_file_exists "herdr installer exists" "$HERDR_INSTALLER"
assert_file_executable "herdr menu is executable" "$HERDR_MENU"
assert_file_executable "herdr installer is executable" "$HERDR_INSTALLER"
assert_file_contains "herdr menu uses strict mode" "$HERDR_MENU" "set -euo pipefail"
assert_file_contains "herdr installer uses strict mode" "$HERDR_INSTALLER" "set -euo pipefail"
assert_true "herdr menu has no raw failure suppression" \
    "! grep -qE '\\|\\|[[:space:]]*true\\b' '$HERDR_MENU'"
assert_true "herdr installer has no raw failure suppression" \
    "! grep -qE '\\|\\|[[:space:]]*true\\b' '$HERDR_INSTALLER'"
assert_file_contains "herdr installer sources the i18n library" "$HERDR_INSTALLER" "i18n.sh"
assert_file_contains "herdr installer calls i18n_init" "$HERDR_INSTALLER" "i18n_init"
assert_file_contains "herdr installer sources the user config library" "$HERDR_INSTALLER" "userconf.sh"
assert_file_contains "herdr installer deploys through the shared helper" "$HERDR_INSTALLER" 'install_user_file.*755'
assert_file_contains "herdr installer manages the hyprland binding block" "$HERDR_INSTALLER" "bindings.lua"
assert_file_contains "herdr installer unbinds the upstream key" "$HERDR_INSTALLER" 'hl.unbind..SUPER [+] CTRL [+] K'
assert_file_contains "herdr installer rebinds super-ctrl-k to the menu" "$HERDR_INSTALLER" 'o.bind..SUPER [+] CTRL [+] K'
assert_file_contains "herdr installer warns when bindings are missing" "$HERDR_INSTALLER" "herdr.bind_skipped"
assert_file_contains "herdr installer logs completion" "$HERDR_INSTALLER" "install.herdr_done"
assert_true "herdr installer has no untranslated literal message" \
    "! grep -qE '^[[:space:]]*(log|warn|err) \"[^\"]* [^\"]*\"' '$HERDR_INSTALLER'"
assert_true "herdr installer hardcodes no user home" \
    "! grep -qE '/home/[a-z]' '$HERDR_INSTALLER'"

test_section "Records: Display Parity & Raw Channel"

assert_true "menu library extracts cleanly" "menu_lib"
assert_true "sandbox records generated" "gen_records && [[ -s '$SB/records.txt' ]]"
assert_true "every record carries display and raw columns" \
    "awk -F'\t' 'NF!=2{bad=1} END{exit bad?1:0}' '$SB/records.txt'"
assert_true "prefix row comes first" \
    "head -n 1 '$SB/records.txt' | grep -q '^PREFIX'"
assert_true "display column keeps the upstream width format" \
    "grep -qE '^.{32} → ' '$SB/records.txt'"
assert_true "user prefix override wins" \
    "grep -q '^PREFIX.*CTRL [+] SPACE' '$SB/records.txt'"
assert_true "user action override wins" \
    "grep -q 'PREFIX [+] T.*New tab' '$SB/records.txt'"
assert_true "unbound user action disappears" \
    "! grep -q 'Close pane' '$SB/records.txt'"
assert_true "prose lines never parse as bindings" \
    "! grep -qi 'popup opens' '$SB/records.txt'"
assert_true "custom commands never leak into the menu" \
    "! grep -q 'prefix+alt+g' '$SB/records.txt'"
assert_true "navigate rows keep their mode prefix" \
    "grep -q '^NAVIGATE [+] H.*Pane left' '$SB/records.txt'"
assert_true "array binding replays its first alternative" \
    "grep 'Split horizontal' '$SB/records.txt' | grep -q 'prefix+h$'"
assert_true "raw bindings are lowercase" \
    "! awk -F'\t' '{print \$2}' '$SB/records.txt' | grep -q '[A-Z]'"
assert_true "print mode shows display only" \
    "PATH='$SB/fakebin:$PATH' HERDR_CONFIG_PATH='$SB/user.toml' bash '$HERDR_MENU' --print 2>/dev/null | grep -q '^PREFIX' && ! PATH='$SB/fakebin:$PATH' HERDR_CONFIG_PATH='$SB/user.toml' bash '$HERDR_MENU' --print 2>/dev/null | grep -qP '\t'"

test_section "Prefix Resolution"

assert_true "user config prefix wins" \
    "PATH='$SB/fakebin:$PATH' HERDR_CONFIG_PATH='$SB/user.toml' bash -c 'source \"$SB/menu-lib.sh\" >/dev/null 2>&1; [[ \"\$(resolve_herdr_prefix)\" == ctrl+space ]]'"
assert_true "default prefix applies without user override" \
    "PATH='$SB/fakebin:$PATH' HERDR_CONFIG_PATH='$SB/noprefix.toml' bash -c 'source \"$SB/menu-lib.sh\" >/dev/null 2>&1; [[ \"\$(resolve_herdr_prefix)\" == ctrl+b ]]'"
assert_true "empty default falls back to ctrl+b" \
    "PATH='$SB/fakebin:$PATH' HERDR_CONFIG_PATH='$SB/noprefix.toml' HERDR_FAKE_EMPTY=1 bash -c 'source \"$SB/menu-lib.sh\" >/dev/null 2>&1; [[ \"\$(resolve_herdr_prefix)\" == ctrl+b ]]'"

test_section "Key Replay Mapping"

replay_log() (
    fake_env
    # shellcheck source=/dev/null
    source "$SB/menu-lib.sh"
    set +e
    rm -f "$SB/wtype.log"
    replay_herdr_keys "$1" >/dev/null 2>&1
)

assert_true "prefix action replays prefix chord then key" \
    "replay_log 'prefix+c' && grep -q '<-M><ctrl><-k><space><-m><ctrl>' '$SB/wtype.log' && grep -q '<-k><c>' '$SB/wtype.log'"
assert_true "prefix chord holds shift for capitals" \
    "replay_log 'prefix+shift+n' && grep -q '<-M><shift><-k><n><-m><shift>' '$SB/wtype.log'"
assert_true "direct chord replays modifiers together" \
    "replay_log 'ctrl+alt+left' && grep -q '<-M><ctrl><-M><alt><-k><Left><-m><alt><-m><ctrl>' '$SB/wtype.log'"
assert_true "enter maps to the xkb return key" \
    "replay_log 'alt+enter' && grep -q '<-M><alt><-k><Return><-m><alt>' '$SB/wtype.log'"
assert_true "navigate mode replays the bare key" \
    "replay_log 'navigate+h' && grep -q '<-k><h>' '$SB/wtype.log' && [[ \$(wc -l < '$SB/wtype.log') -eq 1 ]]"
assert_true "indexed ranges replay nothing" \
    "replay_log 'prefix+1..9' && [[ ! -s '$SB/wtype.log' ]]"
assert_true "bare prefix replays the resolved chord" \
    "replay_log 'prefix' && grep -q '<-M><ctrl><-k><space><-m><ctrl>' '$SB/wtype.log'"
assert_true "punctuation maps to xkb names" \
    "replay_log 'prefix+?' && grep -q '<-k><?>' '$SB/wtype.log'"

test_section "Process Gating & End-to-End"

e2e_run() (
    fake_env
    rm -f "$SB/hyprctl.log" "$SB/wtype.log"
    export HERDR_FAKE_RUNNING=1 HERDR_FAKE_NAME_MATCH=1 HERDR_FAKE_EMPTY=0 HERDR_FAKE_PIDS="" HERDR_FAKE_CPID="424242"
    export HERDR_FAKE_SELECT_MODE="" HERDR_FAKE_SELECTION=""
    case "${1:-}" in
        cancel)
            HERDR_FAKE_SELECT_MODE="cancel"
            ;;
        down)
            HERDR_FAKE_RUNNING=0
            HERDR_FAKE_PIDS=""
            HERDR_FAKE_SELECTION="$(bash "$HERDR_MENU" --print 2>/dev/null | head -n 1)"
            [[ -n "$HERDR_FAKE_SELECTION" ]] || return 1
            ;;
        named)
            HERDR_FAKE_SELECTION="$(bash "$HERDR_MENU" --print 2>/dev/null | grep -F 'New tab')"
            [[ -n "$HERDR_FAKE_SELECTION" ]] || return 1
            ;;
        pids)
            HERDR_FAKE_NAME_MATCH=0
            HERDR_FAKE_CPID="$$"
            HERDR_FAKE_PIDS="$$"
            printf '[{"address":"%s","pid":%s,"class":"kitty","title":"shell","initialClass":"","initialTitle":""}]' "$FAKE_ADDR" "$$" > "$SB/clients.json"
            HERDR_FAKE_SELECTION="$(bash "$HERDR_MENU" --print 2>/dev/null | grep -F 'Workspace picker')"
            [[ -n "$HERDR_FAKE_SELECTION" ]] || return 1
            ;;
        empty)
            HERDR_FAKE_EMPTY=1
            HERDR_CONFIG_PATH="$SB/empty.toml"
            ;;
    esac
    export HERDR_FAKE_RUNNING HERDR_FAKE_NAME_MATCH HERDR_FAKE_EMPTY HERDR_FAKE_PIDS HERDR_FAKE_CPID HERDR_FAKE_SELECT_MODE HERDR_FAKE_SELECTION
    bash "$HERDR_MENU" >/dev/null 2>&1
    rc=$?
    printf '[{"address":"%s","pid":424242,"class":"kitty","title":"host: work","initialClass":"","initialTitle":"herdr"}]' "$FAKE_ADDR" > "$SB/clients.json"
    return "$rc"
)

assert_true "cancelled menu exits cleanly without side effects" \
    "e2e_run cancel && ! grep -q 'focus' '$SB/hyprctl.log' 2>/dev/null && [[ ! -s '$SB/wtype.log' ]]"
assert_true "server down performs no dispatch" \
    "e2e_run down && ! grep -q 'focus' '$SB/hyprctl.log' 2>/dev/null && [[ ! -s '$SB/wtype.log' ]]"
assert_true "named herdr window is focused and fed" \
    "e2e_run named && grep -q '$FAKE_ADDR' '$SB/hyprctl.log' && grep -q '<-k><t>' '$SB/wtype.log'"
assert_true "pid fallback finds the hosting terminal" \
    "e2e_run pids && grep -q '$FAKE_ADDR' '$SB/hyprctl.log' && grep -q '<-k><w>' '$SB/wtype.log'"
assert_true "empty listing exits silently" \
    "e2e_run empty && [[ ! -s '$SB/hyprctl.log' ]]"
assert_true "print mode needs no running server" \
    "HERDR_FAKE_RUNNING=0 HERDR_FAKE_PIDS='' PATH='$SB/fakebin:$PATH' HERDR_CONFIG_PATH='$SB/user.toml' bash '$HERDR_MENU' --print 2>/dev/null | grep -q '^PREFIX'"

test_section "Installer Behaviour in Sandbox"

sandbox_install() (
    export HOME="$SB/home" XDG_CONFIG_HOME="$SB/home/.config" XDG_DATA_HOME="$SB/home/.local/share"
    export OMACONF_LANG="${1:-en}"
    if [[ "${3:-reset}" != "keep" ]]; then
        rm -rf "${SB:?}/home"
        mkdir -p "$SB/home/.config/hypr" "$SB/home/.local/share"
        if [[ "${2:-1}" == "1" ]]; then
            printf 'o.bind("SUPER + RETURN", "Terminal", "xdg-terminal-exec")\n' > "$SB/home/.config/hypr/bindings.lua"
        fi
    fi
    bash "$HERDR_INSTALLER" > "$SB/install.out" 2> "$SB/install.err"
    printf '%s' "$?"
)

assert_true "sandbox install succeeds" \
    "[[ \"\$(sandbox_install en 1)\" == 0 ]]"
assert_true "menu lands user scoped with 755" \
    "[[ -x '$SB/home/.local/share/omaconf/herdr-keybindings-menu' ]] && [[ \"\$(stat -c %a '$SB/home/.local/share/omaconf/herdr-keybindings-menu')\" == 755 ]]"
assert_true "existing bindings survive the managed block" \
    "grep -q 'SUPER + RETURN' '$SB/home/.config/hypr/bindings.lua' && grep -q 'omaconf-herdr-keys (managed)' '$SB/home/.config/hypr/bindings.lua'"
assert_true "managed block unbinds then rebinds super-ctrl-k" \
    "grep -q 'hl.unbind(\"SUPER + CTRL + K\")' '$SB/home/.config/hypr/bindings.lua' && grep -q 'o.bind(\"SUPER + CTRL + K\", \"Herdr keybindings\"' '$SB/home/.config/hypr/bindings.lua'"
assert_true "repeated installs converge byte for byte" \
    "cp '$SB/home/.config/hypr/bindings.lua' '$SB/once.lua' && sandbox_install en 1 keep >/dev/null && sandbox_install en 1 keep >/dev/null && cmp -s '$SB/once.lua' '$SB/home/.config/hypr/bindings.lua'"
assert_true "exactly one managed block survives" \
    "[[ \$(grep -c '^-- omaconf-herdr-keys (managed)$' '$SB/home/.config/hypr/bindings.lua') -eq 1 ]]"
assert_true "missing bindings file warns but succeeds" \
    "[[ \"\$(sandbox_install en 0)\" == 0 ]] && grep -q 'Hyprland Herdr binding skipped' '$SB/install.err'"
assert_true "english completion message is exact" \
    "sandbox_install en 1 >/dev/null && grep -qx 'Herdr keybindings menu installed successfully.' '$SB/install.out'"
assert_true "italian completion message is exact" \
    "sandbox_install it 1 >/dev/null && grep -qx 'Menu dei tasti di Herdr installato con successo.' '$SB/install.out'"
assert_true "replaced menu keeps a single slot backup" \
    "sandbox_install en 1 >/dev/null && printf 'stale' > '$SB/home/.local/share/omaconf/herdr-keybindings-menu' && sandbox_install en 1 keep >/dev/null && [[ -f '$SB/home/.local/share/omaconf/herdr-keybindings-menu.bak' ]] && [[ \$(ls '$SB/home/.local/share/omaconf' | grep -c 'herdr-keybindings-menu') -eq 2 ]]"

test_section "Wiring, Provisioning & Catalogues"

assert_file_contains "make herdr runs the installer" "$PROJECT_DIR/Makefile" 'herdr:'
assert_true "make herdr body calls herdrconf" \
    "grep -A1 '^herdr:' '$PROJECT_DIR/Makefile' | grep -q 'herdrconf/install.sh'"
assert_file_contains "make phony lists herdr" "$PROJECT_DIR/Makefile" 'herdr'
assert_file_contains "make lint covers herdrconf" "$PROJECT_DIR/Makefile" 'herdrconf/'
assert_file_contains "make help lists herdr" "$PROJECT_DIR/scripts/lib/help.sh" 'row herdr "make.herdr"'
assert_file_contains "defaults module provisions herdrconf per user" "$PROJECT_DIR/scripts/modules/20-defaults.sh" "herdrconf/install.sh"
assert_true "defaults provisioning degrades per user" \
    "grep -A4 'herdrconf/install.sh' '$PROJECT_DIR/scripts/modules/20-defaults.sh' | grep -q 'defaults.herdrconf_skipped'"
assert_true "defaults provisioning logs its stage" \
    "grep -q 'log \"defaults.herdrconf\"' '$PROJECT_DIR/scripts/modules/20-defaults.sh'"
assert_file_contains "ci syntax job covers herdrconf" "$PROJECT_DIR/.github/workflows/ci.yml" 'herdrconf/'
assert_file_contains "test runner includes the herdr suite" "$PROJECT_DIR/tests/run-all.sh" "test_herdr_menu.sh"

for lang in en it fr de es pt; do
    assert_true "catalogue $lang carries the herdr keys" \
        "for k in make.herdr install.herdr_done defaults.herdrconf defaults.herdrconf_skipped herdr.bind_skipped; do grep -q \"^\$k=\" '$MSG_DIR/$lang.msg' || exit 1; done"
done

assert_true "herdr keys keep placeholder parity" \
    "for k in make.herdr install.herdr_done defaults.herdrconf defaults.herdrconf_skipped herdr.bind_skipped; do n=\$(awk -F%s -v k=\"^\$k=\" '\$0 ~ k { print NF - 1 }' \"\$MSG_DIR/en.msg\"); for l in it fr de es pt; do m=\$(awk -F%s -v k=\"^\$k=\" '\$0 ~ k { print NF - 1 }' \"\$MSG_DIR/\$l.msg\"); [[ \"\$n\" == \"\$m\" ]] || exit 1; done; done"

if [[ -x /usr/bin/omarchy-menu-herdr-keybindings || -x /usr/share/omarchy/bin/omarchy-menu-herdr-keybindings ]] && command -v herdr &>/dev/null; then
    UPSTREAM="$(command -v omarchy-menu-herdr-keybindings)"
    assert_true "display column matches upstream omarchy" \
        "diff -q <(bash '$HERDR_MENU' --print 2>/dev/null) <(bash '$UPSTREAM' --print 2>/dev/null) >/dev/null"
else
    assert_warn "upstream parity skipped outside omarchy" "false"
fi

test_summary

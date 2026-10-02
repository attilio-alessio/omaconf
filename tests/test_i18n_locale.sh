#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIB_DIR="$PROJECT_DIR/scripts/lib"
MSG_DIR="$LIB_DIR/messages"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Internationalization Engine & System Locale"

SUPPORTED=(en it fr de es pt)

for lang in "${SUPPORTED[@]}"; do
    assert_file_exists "catalog $lang.msg exists" "$MSG_DIR/$lang.msg"
done

assert_file_exists "i18n library exists" "$LIB_DIR/i18n.sh"
assert_file_exists "i18n bootstrap exists" "$LIB_DIR/i18n-boot.sh"
assert_file_exists "help script exists" "$LIB_DIR/help.sh"
assert_true "i18n library leaves caller shell options untouched" \
    "bash -c 'set +e +u; source \"$LIB_DIR/i18n.sh\"; [[ \$- != *e* && \$- != *u* ]]'"
assert_true "locale map library leaves caller shell options untouched" \
    "bash -c 'set +e +u; source \"$LIB_DIR/locale-map.sh\"; [[ \$- != *e* && \$- != *u* ]]'"
assert_file_contains "i18n library declares associative array" "$LIB_DIR/i18n.sh" "declare -gA OMACONF_I18N"
assert_file_contains "i18n library defines t()" "$LIB_DIR/i18n.sh" "^t\(\) \{"
assert_file_contains "i18n library defines log()" "$LIB_DIR/i18n.sh" "^log\(\) \{"
assert_file_contains "i18n library defines warn()" "$LIB_DIR/i18n.sh" "^warn\(\) \{"
assert_file_contains "i18n library defines err()" "$LIB_DIR/i18n.sh" "^err\(\) \{"
assert_file_contains "i18n library uses printf format indirection safely" "$LIB_DIR/i18n.sh" 'printf -- "\$format"'

for lang in "${SUPPORTED[@]}"; do
    assert_true "catalog $lang has the same keys as en" \
        "diff -q <(grep -oE '^[^=#]+' '$MSG_DIR/en.msg' | sort -u) <(grep -oE '^[^=#]+' '$MSG_DIR/$lang.msg' | sort -u)"
done

for lang in "${SUPPORTED[@]}"; do
    assert_true "catalog $lang keeps the same %s placeholders as en" \
        "diff -q <(awk -F= '{n=gsub(/%s/,\"\",\$2); print \$1\" \"n}' '$MSG_DIR/en.msg') <(awk -F= '{n=gsub(/%s/,\"\",\$2); print \$1\" \"n}' '$MSG_DIR/$lang.msg')"
done

no_empty_translation() {
    local catalog="$1"
    ! awk -F= 'length($1) > 0 && $2 == "" { found = 1 } END { exit found ? 0 : 1 }' "$catalog"
}

for lang in "${SUPPORTED[@]}"; do
    assert_true "catalog $lang has no empty translation" "no_empty_translation '$MSG_DIR/$lang.msg'"
done

no_doubled_prefix() {
    local catalog="$1"
    ! awk '{ i = index($0, "="); if (i == 0) next; k = substr($0, 1, i - 1); v = substr($0, i + 1); if (v ~ ("^" k "=")) found = 1 } END { exit found ? 0 : 1 }' "$catalog"
}

for lang in "${SUPPORTED[@]}"; do
    assert_true "catalog $lang has no value repeating its own key" "no_doubled_prefix '$MSG_DIR/$lang.msg'"
done

render() {
    local lang="$1"
    shift
    OMACONF_LANG="$lang" bash "$LIB_DIR/i18n.sh" --render "$@" 2>/dev/null
}

MSG_COUNT_IT=$(OMACONF_LANG=it bash "$LIB_DIR/i18n.sh" 2>/dev/null | sed -n 's/^messages=//p')
FALLBACK_LANG=$(OMACONF_LANG=zz bash "$LIB_DIR/i18n.sh" 2>/dev/null | sed -n 's/^language=//p')
WARNING_IT=$(OMACONF_LANG=it bash -c 'source "$1/i18n.sh"; i18n_init >/dev/null 2>&1; t "__warning"' _ "$LIB_DIR")
ERROR_DE=$(OMACONF_LANG=de bash -c 'source "$1/i18n.sh"; i18n_init >/dev/null 2>&1; t "__error"' _ "$LIB_DIR")
UNKNOWN_IT=$(OMACONF_LANG=it bash -c 'source "$1/i18n.sh"; i18n_init >/dev/null 2>&1; t "totally.unknown.key"' _ "$LIB_DIR")
PKG_IT=$(OMACONF_LANG=it bash -c 'source "$1/i18n.sh"; i18n_init >/dev/null 2>&1; t "check.pkg_installed" "brave-origin"' _ "$LIB_DIR")
HELP_IT=$(OMACONF_LANG=it bash "$LIB_DIR/help.sh" 2>/dev/null | sed -n 's/^  setup *//p')

eq() { [[ "$1" == "$2" ]]; }
ne() { [[ -n "$1" && "$1" != "$2" ]]; }
list_contains() { printf '%s\n' "$1" | grep -qF "$2"; }
list_marks() { printf '%s\n' "$1" | awk -v l="$2" -v m="$3" '$1 == l && $2 == m { f = 1 } END { exit f ? 0 : 1 }'; }

COMPLETE_IT="$(render it '__complete')"
COMPLETE_EN="$(render en '__complete')"
COMPLETE_FR="$(render fr '__complete')"
COMPLETE_DE="$(render de '__complete')"
COMPLETE_ES="$(render es '__complete')"
COMPLETE_PT="$(render pt '__complete')"
SUMMARY_IT="$(render it 'verify.passed_summary' '7' '2')"
KEYMAP_IT="$(render it 'locale.keymap' 'it')"

assert_true "engine detects OMACONF_LANG override"    "eq \"\$COMPLETE_IT\" 'Hardening completato. Riavvio necessario.'"
assert_true "engine renders english"                   "eq \"\$COMPLETE_EN\" 'Hardening complete. Reboot required.'"
assert_true "engine renders french"                   "ne \"\$COMPLETE_FR\" \"\$COMPLETE_EN\""
assert_true "engine renders german"                   "ne \"\$COMPLETE_DE\" \"\$COMPLETE_EN\""
assert_true "engine renders spanish"                  "ne \"\$COMPLETE_ES\" \"\$COMPLETE_EN\""
assert_true "engine renders portuguese"               "ne \"\$COMPLETE_PT\" \"\$COMPLETE_EN\""
assert_true "engine substitutes printf arguments"     "eq \"\$PKG_IT\" 'brave-origin installato'"
assert_true "engine handles multiple printf arguments" "eq \"\$SUMMARY_IT\" 'Superati: 7  Falliti: 2'"
assert_true "engine substitutes arguments in any key"  "eq \"\$KEYMAP_IT\" 'Tastiera console di destinazione: it'"
assert_true "engine falls back for unknown key"       "eq \"\$UNKNOWN_IT\" 'totally.unknown.key'"
assert_true "engine falls back for unsupported language" "eq \"\$FALLBACK_LANG\" 'en'"
assert_true "engine loads the full catalog"           "[[ \"\$MSG_COUNT_IT\" -gt 300 ]]"
assert_true "warning label is localized"              "eq \"\$WARNING_IT\" 'Attenzione'"
assert_true "error label is localized"                "eq \"\$ERROR_DE\" 'Fehler'"
LIST_IT="$(OMACONF_LANG=it bash "$LIB_DIR/i18n.sh" --list 2>/dev/null)"
assert_true "engine lists available languages"       "list_contains \"\$LIST_IT\" 'Lingue disponibili'"
assert_true "engine marks the current language"      "list_marks \"\$LIST_IT\" it '(corrente)'"
assert_true "make lang target lists languages"       "grep -q 'i18n.sh --list' '$PROJECT_DIR/Makefile'"
BOOT_IT="$(OMACONF_LANG=it bash -c 'SCRIPT_DIR="$1"; source "$2"; t "__complete"' _ "$LIB_DIR" "$LIB_DIR/i18n-boot.sh" 2>/dev/null)"
BOOT_STUB="$(SCRIPT_DIR=/nonexistent OMACONF_LANG=it bash -c 'source "$1"; warn stub' _ "$LIB_DIR/i18n-boot.sh" 2>&1)"
assert_true "boot shim resolves the library catalog"    "eq \"\$BOOT_IT\" 'Hardening completato. Riavvio necessario.'"
assert_true "boot shim degrades to an english stub"     "eq \"\$BOOT_STUB\" 'Warning: stub'"
assert_true "boot shim keeps working under strict mode" "bash -c 'set -euo pipefail; SCRIPT_DIR=\"\$1\"; source \"\$1/i18n-boot.sh\"; t ok' _ '$LIB_DIR'"
assert_true "make help is localized"                  "eq \"\$HELP_IT\" 'Esegui la configurazione completa (root)'"

assert_file_contains "setup.sh sources the i18n library" "$PROJECT_DIR/scripts/setup.sh" "lib/i18n.sh"
assert_file_contains "setup.sh calls i18n_init" "$PROJECT_DIR/scripts/setup.sh" "i18n_init"
assert_file_contains "verify.sh sources the i18n library" "$PROJECT_DIR/scripts/verify.sh" "lib/i18n.sh"
assert_file_contains "verify.sh has a locale section" "$PROJECT_DIR/scripts/verify.sh" "section verify.sec_locale"
assert_file_contains "run-setup.sh sources the i18n library" "$PROJECT_DIR/scripts/run-setup.sh" "lib/i18n.sh"
assert_file_contains "launch.sh sources the i18n library" "$PROJECT_DIR/scripts/launch.sh" "lib/i18n.sh"
assert_file_contains "Makefile exposes lang target" "$PROJECT_DIR/Makefile" "^lang:"
assert_file_contains "Makefile exposes nvim target" "$PROJECT_DIR/Makefile" "^nvim:"
assert_file_contains "Makefile exposes cli target" "$PROJECT_DIR/Makefile" "^cli:"
assert_file_contains "Makefile exposes herdr target" "$PROJECT_DIR/Makefile" "^herdr:"
assert_file_contains "Makefile help is translated" "$PROJECT_DIR/Makefile" "lib/help.sh"
assert_file_contains "Makefile hook target installs the i18n runtime" "$PROJECT_DIR/Makefile" "hooks/i18n"

for installer in zedconf microconf nvimconf yaziconf cliconf herdrconf; do
    assert_file_contains "$installer sources the i18n library" "$PROJECT_DIR/$installer/install.sh" "i18n.sh"
done

for hook in hooks/theme-set.d/folder-color hooks/theme-set.d/micro-theme hooks/theme-set.d/btop-theme \
            hooks/theme-set.d/shell-icons hooks/theme-set.d/yazi-theme hooks/theme-set.d/cli-theme \
            hooks/pre-refresh-pacman.d/99-omaconf-persist hooks/post-update.d/99-omaconf-persist; do
    assert_file_contains "$(basename "$(dirname "$hook")")/$(basename "$hook") bootstraps i18n" "$PROJECT_DIR/$hook" "i18n-boot.sh"
done

for module in "$PROJECT_DIR"/scripts/modules/*.sh; do
    [[ -f "$module" ]] || continue
    mname=$(basename "$module")
    assert_true "module $mname has no untranslated literal message" \
        "! grep -qE '^[[:space:]]*(log|warn|err) \"[^\"]* [^\"]*\"' '$module'"
done

assert_true "verify.sh has no untranslated literal section" \
    "! grep -qE '^section \"' '$PROJECT_DIR/scripts/verify.sh'"
assert_file_contains "verify normalises locale codes before checking" "$PROJECT_DIR/scripts/verify.sh" "locale_generated()"
assert_file_contains "verify folds case and dashes in locale codes" "$PROJECT_DIR/scripts/verify.sh" "tr -d .-"
assert_true "catalogs contain no stray percent signs" \
    "! grep -qE '%[^s]' '$MSG_DIR/en.msg'"
assert_true "catalogs contain no keys with spaces" \
    "! grep -qE '^[^=#]+ [^=]*=' '$MSG_DIR/en.msg'"
assert_true "no hook keeps a hardcoded english warning label" \
    "! grep -rq 'warning: ' '$PROJECT_DIR/hooks'"
assert_true "verify.sh has no untranslated literal check" \
    "! grep -qE '^[[:space:]]+check \"[a-zA-Z]' '$PROJECT_DIR/scripts/verify.sh'"

assert_file_exists "locale module exists" "$PROJECT_DIR/scripts/modules/05-locale.sh"
assert_file_contains "setup.sh references locale module" "$PROJECT_DIR/scripts/setup.sh" "05-locale.sh"
assert_file_exists "locale map library exists" "$PROJECT_DIR/scripts/lib/locale-map.sh"
assert_file_contains "locale module sources the locale map" "$PROJECT_DIR/scripts/modules/05-locale.sh" "lib/locale-map.sh"
assert_file_contains "locale map resolves target locale" "$PROJECT_DIR/scripts/lib/locale-map.sh" "resolve_target_locale\(\)"
assert_file_contains "locale map resolves console keymap" "$PROJECT_DIR/scripts/lib/locale-map.sh" "resolve_target_keymap\(\)"
assert_file_contains "locale map resolves xkb layout" "$PROJECT_DIR/scripts/lib/locale-map.sh" "resolve_target_xkb\(\)"
assert_file_contains "locale map detects the system timezone" "$PROJECT_DIR/scripts/lib/locale-map.sh" "detect_system_timezone\(\)"
assert_true "locale map is side effect free" "! grep -qE '(^|[[:space:]])(rm|mv|cp|sed -i|tee|localectl|locale-gen)([[:space:]]|$)' '$PROJECT_DIR/scripts/lib/locale-map.sh'"
assert_file_contains "locale module writes locale.conf" "$PROJECT_DIR/scripts/modules/05-locale.sh" "/etc/locale.conf"
assert_file_contains "locale module writes vconsole.conf" "$PROJECT_DIR/scripts/modules/05-locale.sh" "/etc/vconsole.conf"
assert_file_contains "locale module writes profile snippet" "$PROJECT_DIR/scripts/modules/05-locale.sh" "omaconf-locale.sh"
assert_file_contains "locale module enables locale.gen entries" "$PROJECT_DIR/scripts/modules/05-locale.sh" "locale_enable_gen\(\)"
assert_file_contains "locale module applies Hyprland kb_layout" "$PROJECT_DIR/scripts/modules/05-locale.sh" "kb_layout"
assert_file_contains "locale map keeps a us locale entry for us zones" "$PROJECT_DIR/scripts/lib/locale-map.sh" "en_US.UTF-8"
assert_file_contains "locale module keeps LC_COLLATE deterministic" "$PROJECT_DIR/scripts/modules/05-locale.sh" "LC_COLLATE=C"
assert_file_contains "locale module sets LANGUAGE" "$PROJECT_DIR/scripts/modules/05-locale.sh" "LANGUAGE="

assert_true "locale module maps Europe/Rome to italian" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_locale Europe/Rome)\" == it_IT.UTF-8 ]]'"
assert_true "locale module maps Europe/Paris to french" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_locale Europe/Paris)\" == fr_FR.UTF-8 ]]'"
assert_true "locale module maps Europe/Berlin to german" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_locale Europe/Berlin)\" == de_DE.UTF-8 ]]'"
assert_true "locale module maps Europe/Madrid to spanish" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_locale Europe/Madrid)\" == es_ES.UTF-8 ]]'"
assert_true "locale module maps Europe/Lisbon to portuguese" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_locale Europe/Lisbon)\" == pt_PT.UTF-8 ]]'"
assert_true "locale module maps America/New_York to us english" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_locale America/New_York)\" == en_US.UTF-8 ]]'"
assert_true "locale module maps Europe/Rome to the it console keymap" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_keymap Europe/Rome)\" == it ]]'"
assert_true "locale module maps Europe/Rome to the it xkb layout" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_xkb Europe/Rome)\" == it ]]'"
assert_true "locale module maps Europe/Berlin to the de xkb layout" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_xkb Europe/Berlin)\" == de ]]'"
assert_true "locale module falls back to us for unknown zones" \
    "bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; [[ \"\$(resolve_target_xkb Antarctica/Rothera)\" == us ]]'"

tz_resolve() {
    local tz="$1"
    local fn="$2"
    bash -c "source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; $fn \"$tz\""
}

no_legacy_marker() {
    ! grep -q 'omaconf locale layout' "$1" 2>/dev/null
}

assert_tz() {
    local tz="$1" exp_locale="$2" exp_keymap="$3" exp_xkb="$4"
    assert_true "locale map resolves $tz locale"     "eq \"\$(tz_resolve '$tz' resolve_target_locale)\" '$exp_locale'"
    assert_true "locale map resolves $tz keymap"     "eq \"\$(tz_resolve '$tz' resolve_target_keymap)\" '$exp_keymap'"
    assert_true "locale map resolves $tz xkb layout" "eq \"\$(tz_resolve '$tz' resolve_target_xkb)\" '$exp_xkb'"
}

assert_tz "Europe/London"        "en_GB.UTF-8" "uk"         "gb"
assert_tz "Europe/Warsaw"        "pl_PL.UTF-8" "pl"         "pl"
assert_tz "Europe/Athens"        "el_GR.UTF-8" "gr"         "gr"
assert_tz "America/Sao_Paulo"    "pt_BR.UTF-8" "br-abnt2"   "br"
assert_tz "America/Montreal"     "fr_CA.UTF-8" "cf"         "fr"
assert_tz "America/Mexico_City"  "es_MX.UTF-8" "la-latin1"  "latam"
assert_tz "Asia/Dubai"           "ar_AE.UTF-8" "ara"        "ae"
assert_tz "Australia/Sydney"     "en_AU.UTF-8" "us"         "us"

assert_true "locale map honours the forced timezone override" \
    "eq \"\$(OMACONF_FORCE_TZ=Europe/Berlin bash -c 'source \"$PROJECT_DIR/scripts/lib/locale-map.sh\"; detect_system_timezone')\" 'Europe/Berlin'"

test_section "Desktop Locale Application"

LOCALE_MODULE="$PROJECT_DIR/scripts/modules/05-locale.sh"

assert_file_contains "locale module is importable without side effects" "$LOCALE_MODULE" 'OMACONF_LOCALE_LIB_ONLY'
assert_file_contains "locale module passes the resolved xkb layout, not the console keymap" "$LOCALE_MODULE" 'LOCALE_TARGET. ..LOCALE_XKB'
assert_file_not_contains "locale module never re-resolves xkb from a keymap" "$LOCALE_MODULE" 'resolve_target_xkb "$keymap"'
assert_file_contains "locale module exports the language to the desktop session" "$LOCALE_MODULE" 'hl.env\("LANG"'

apply_locale() {
    local homes="$1"
    OMACONF_LOCALE_LIB_ONLY=1 OMACONF_HOMES_ROOT="$homes" bash -c '
        log() { :; }; warn() { :; }; err() { :; }
        source "'"$LOCALE_MODULE"'"
        locale_apply_hyprland "$(resolve_target_locale Europe/Rome)" "$(resolve_target_xkb Europe/Rome)"
    ' 2>/dev/null
}

HOMES_TMP=$(mktemp -d)
mkdir -p "$HOMES_TMP/tester/.config/hypr"
printf 'hl.config({ input = { kb_options = "" } })\n' > "$HOMES_TMP/tester/.config/hypr/input.lua"

apply_locale "$HOMES_TMP"
INPUT_LUA="$HOMES_TMP/tester/.config/hypr/input.lua"
FIRST_SIZE=$(wc -c < "$INPUT_LUA")

assert_file_contains "desktop input gets the resolved italian layout" "$INPUT_LUA" 'kb_layout = "it"'
assert_file_contains "desktop session gets the italian language" "$INPUT_LUA" 'hl.env\("LANG", "it_IT.UTF-8"\)'
assert_file_contains "desktop session gets the italian LANGUAGE" "$INPUT_LUA" 'hl.env\("LANGUAGE", "it"\)'

apply_locale "$HOMES_TMP"
apply_locale "$HOMES_TMP"
assert_true "locale block stays idempotent across repeated runs" \
    "eq \"\$(grep -cE '^-- omaconf locale \\(managed\\)$' '$INPUT_LUA')\" 1"
assert_true "locale block does not grow across repeated runs" \
    "eq \"\$(wc -c < '$INPUT_LUA')\" '$FIRST_SIZE'"

printf -- '-- omaconf locale layout (managed)\nhl.config({\n  input = {\n    kb_layout = "us",\n  },\n})\n-- end omaconf locale layout (managed)\n' > "$INPUT_LUA"
apply_locale "$HOMES_TMP"
assert_true "legacy locale block marker is migrated away" "no_legacy_marker '$INPUT_LUA'"
assert_file_contains "legacy us layout is replaced by the resolved layout" "$INPUT_LUA" 'kb_layout = "it"'
assert_true "migration leaves exactly one managed block" \
    "eq \"\$(grep -cE '^-- omaconf locale \\(managed\\)$' '$INPUT_LUA')\" 1"

rm -rf "$HOMES_TMP"

test_summary

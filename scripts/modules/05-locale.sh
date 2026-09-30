set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/locale-map.sh"

LOCALE_PROFILE="/etc/profile.d/omablot-locale.sh"
HOMES_ROOT="${OMABLOT_HOMES_ROOT:-/home}"

locale_enable_gen() {
    local target="$1"

    [[ -f /etc/locale.gen ]] || return 0

    if grep -qE "^#[[:space:]]*${target}" /etc/locale.gen; then
        sed -i -E "s/^#[[:space:]]*(${target}.*)/\1/" /etc/locale.gen
    elif ! grep -qE "^${target}" /etc/locale.gen; then
        printf '%s UTF-8\n' "$target" >> /etc/locale.gen
    fi

    if grep -qE "^#[[:space:]]*en_US\.UTF-8" /etc/locale.gen; then
        sed -i -E "s/^#[[:space:]]*(en_US\.UTF-8.*)/\1/" /etc/locale.gen
    fi
}

locale_write_conf() {
    local target="$1"

    cat > /etc/locale.conf <<EOF
LANG=$target
LANGUAGE=${target%%_*}
LC_COLLATE=C
EOF
    chmod 644 /etc/locale.conf
}

locale_write_vconsole() {
    local keymap="$1"

    cat > /etc/vconsole.conf <<EOF
KEYMAP=$keymap
EOF
    chmod 644 /etc/vconsole.conf
}

locale_write_profile() {
    local target="$1"

    cat > "$LOCALE_PROFILE" <<EOF
export LANG=$target
export LANGUAGE=${target%%_*}
export LC_COLLATE=C
EOF
    chmod 644 "$LOCALE_PROFILE"
}

locale_apply_hyprland() {
    local target="$1"
    local layout="$2"
    [[ -n "$layout" ]] || layout="us"
    [[ -n "$target" ]] || target="en_US.UTF-8"

    for user_home in "$HOMES_ROOT"/*; do
        [[ -d "$user_home" ]] || continue
        _lu_user=$(basename "$user_home")
        _lu_input="$user_home/.config/hypr/input.lua"

        if [[ ! -f "$_lu_input" ]]; then
            warn "locale.hyprland_missing" "$_lu_user"
            continue
        fi

        _lu_tmp=$(mktemp) || { warn "locale.hyprland_skipped" "$_lu_user"; continue; }
        sed '/^-- omablot locale .*(managed)$/,/^-- end omablot locale .*(managed)$/d' "$_lu_input" 2>/dev/null \
            | sed -e :a -e '/^[[:space:]]*$/{$d;N;ba' -e '}' > "$_lu_tmp" 2>/dev/null \
            || warn "locale.hyprland_skipped" "$_lu_user"

        cat >> "$_lu_tmp" <<EOF

-- omablot locale (managed)
hl.config({
  input = {
    kb_layout = "$layout",
  },
})
hl.env("LANG", "$target")
hl.env("LANGUAGE", "${target%%_*}")
-- end omablot locale (managed)
EOF

        if cat "$_lu_tmp" > "$_lu_input" 2>/dev/null; then
            chown "$_lu_user":"$_lu_user" "$_lu_input" 2>/dev/null || warn "locale.hyprland_skipped" "$_lu_user"
        else
            warn "locale.hyprland_skipped" "$_lu_user"
        fi
        rm -f "$_lu_tmp"
    done
}


locale_main() {
    log "locale.detect"

    LOCALE_TZ=$(detect_system_timezone)
    if [[ -z "$LOCALE_TZ" ]]; then
        warn "locale.tz_detect_skipped"
        LOCALE_TZ="Europe/Rome"
    fi
    LOCALE_TARGET=$(resolve_target_locale "$LOCALE_TZ")
    LOCALE_KEYMAP=$(resolve_target_keymap "$LOCALE_TZ")
    LOCALE_XKB=$(resolve_target_xkb "$LOCALE_TZ")

    log "locale.timezone" "$LOCALE_TZ"
    log "locale.target" "$LOCALE_TARGET"
    log "locale.keymap" "$LOCALE_KEYMAP"
    log "locale.layout" "$LOCALE_XKB"
    log "locale.language_active" "$I18N_LANG"

    log "locale.generate"
    locale_enable_gen "$LOCALE_TARGET"
    if command -v locale-gen &>/dev/null; then
        locale-gen
    else
        warn "locale.gen_missing"
    fi

    locale_write_conf "$LOCALE_TARGET"
    locale_write_vconsole "$LOCALE_KEYMAP"
    log "locale.profile"
    locale_write_profile "$LOCALE_TARGET"

    if command -v localectl &>/dev/null && systemctl is-system-running &>/dev/null; then
        log "locale.apply"
        localectl set-locale LANG="$LOCALE_TARGET" LANGUAGE="${LOCALE_TARGET%%_*}" LC_COLLATE=C \
            || warn "locale.localectl_skipped"
        localectl set-keymap "$LOCALE_KEYMAP" || warn "locale.localectl_skipped"
    fi

    log "locale.hyprland"
    locale_apply_hyprland "$LOCALE_TARGET" "$LOCALE_XKB"

}

if [[ "${OMABLOT_LOCALE_LIB_ONLY:-0}" != "1" ]]; then
    locale_main
fi

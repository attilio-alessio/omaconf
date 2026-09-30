
_omaconf_i18n_stub() {
    t() { printf -- '%s' "$1"; }
    log() { printf '%s\n' "$1"; }
    warn() { printf '%s: %s\n' "Warning" "$1" >&2; }
    err() { printf '%s: %s\n' "Error" "$1" >&2; exit 1; }
}

_omaconf_i18n_resolve() {
    local candidate
    for candidate in \
        "${OMACONF_I18N_DIR:-}/i18n.sh" \
        "${SCRIPT_DIR:-.}/../i18n/i18n.sh" \
        "${SCRIPT_DIR:-.}/../../scripts/lib/i18n.sh"; do
        if [[ -f "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

if _omaconf_i18n_path=$(_omaconf_i18n_resolve) && [[ -f "$_omaconf_i18n_path" ]]; then
    source "$_omaconf_i18n_path" || true
    unset _omaconf_i18n_path
    if declare -F t >/dev/null 2>&1; then
        i18n_init || _omaconf_i18n_stub
    else
        _omaconf_i18n_stub
    fi
else
    unset _omaconf_i18n_path
    _omaconf_i18n_stub
fi

unset -f _omaconf_i18n_resolve _omaconf_i18n_stub

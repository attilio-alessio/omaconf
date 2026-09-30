#!/usr/bin/env bash


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
    # shellcheck disable=SC1090
    if source "$_omaconf_i18n_path"; then
        _omaconf_i18n_loaded=1
    else
        _omaconf_i18n_stub
        warn "Unable to load the internationalization library; using the English fallback."
        _omaconf_i18n_loaded=0
    fi
    unset _omaconf_i18n_path
    if [[ "$_omaconf_i18n_loaded" == 1 ]] && declare -F t >/dev/null 2>&1; then
        if ! i18n_init; then
            _omaconf_i18n_stub
            warn "Unable to initialize internationalization; using the English fallback."
        fi
    else
        _omaconf_i18n_stub
    fi
else
    unset _omaconf_i18n_path
    _omaconf_i18n_stub
fi

unset -f _omaconf_i18n_resolve _omaconf_i18n_stub

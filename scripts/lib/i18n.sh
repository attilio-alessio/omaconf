
I18N_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
I18N_DIR="${OMABLOT_I18N_DIR:-$I18N_LIB_DIR/messages}"
I18N_SUPPORTED=(en it fr de es pt)
I18N_LANG=""

declare -gA OMABLOT_I18N=()

i18n_normalize() {
    local raw="${1,,}"
    raw="${raw%%.*}"
    raw="${raw%%_*}"
    raw="${raw%%@*}"
    printf '%s\n' "$raw"
}

i18n_detect_language() {
    local candidate=""
    local lang=""

    for candidate in "${OMABLOT_LANG:-}" "${LANGUAGE:-}" "${LC_ALL:-}" "${LC_MESSAGES:-}" "${LANG:-}"; do
        if [[ -n "$candidate" && "$candidate" != "C" && "$candidate" != "POSIX" ]]; then
            lang="$(i18n_normalize "$candidate")"
            break
        fi
    done

    if [[ -z "$lang" ]] && [[ -r /etc/locale.conf ]]; then
        lang="$(i18n_normalize "$(sed -n 's/^LANG=//p' /etc/locale.conf | head -1)")"
    fi

    if [[ -z "$lang" || "$lang" == "c" || "$lang" == "posix" ]]; then
        lang="en"
    fi

    printf '%s\n' "$lang"
}

i18n_supported() {
    local want="$1" supported
    for supported in "${I18N_SUPPORTED[@]}"; do
        [[ "$supported" == "$want" ]] && return 0
    done
    return 1
}

i18n_catalog_load() {
    local catalog="$1"
    local line key value

    [[ -r "$catalog" ]] || return 1

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        [[ "$line" != *=* ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        [[ -z "$key" ]] && continue
        OMABLOT_I18N["$key"]="$value"
    done < "$catalog"
}

i18n_init() {
    local lang
    lang="$(i18n_detect_language)"

    if ! i18n_supported "$lang"; then
        lang="en"
    fi

    i18n_catalog_load "$I18N_DIR/en.msg" || return 1
    if [[ "$lang" != "en" ]]; then
        i18n_catalog_load "$I18N_DIR/$lang.msg" || warn "translation catalog missing for $lang, using English"
    fi

    I18N_LANG="$lang"
    export OMABLOT_LANG="$lang"
    return 0
}

t() {
    local msgid="$1"
    shift
    local format="${OMABLOT_I18N[$msgid]:-}"

    [[ -n "$format" ]] || format="$msgid"

    if (( $# > 0 )); then
        printf -- "$format" "$@"
    else
        printf -- '%s' "$format"
    fi
}

log() {
    local msgid="$1"
    shift
    printf '%s\n' "$(t "$msgid" "$@")"
}

warn() {
    local msgid="$1"
    shift
    printf '%s: %s\n' "$(t '__warning')" "$(t "$msgid" "$@")" >&2
}

err() {
    local msgid="$1"
    shift
    printf '%s: %s\n' "$(t '__error')" "$(t "$msgid" "$@")" >&2
    exit 1
}

i18n_status() {
    printf 'language=%s\ncatalog=%s\nmessages=%s\n' "$I18N_LANG" "$I18N_DIR" "${#OMABLOT_I18N[@]}"
}

i18n_list() {
    local lang

    printf '%s\n' "$(t 'i18n.available')"
    for lang in "${I18N_SUPPORTED[@]}"; do
        if [[ "$lang" == "$I18N_LANG" ]]; then
            printf '  %-4s %s\n' "$lang" "$(t 'i18n.current')"
        else
            printf '  %-4s\n' "$lang"
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    i18n_init
    case "${1:-}" in
        --render)
            shift
            t "$@"
            printf '\n'
            ;;
        --list)
            i18n_list
            ;;
        *)
            i18n_status
            ;;
    esac
fi

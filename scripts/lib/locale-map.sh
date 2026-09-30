
detect_system_timezone() {
    local tz="${OMACONF_FORCE_TZ:-}"

    if [[ -z "$tz" ]] && command -v timedatectl &>/dev/null; then
        tz=$(timedatectl show -p Timezone --value 2>/dev/null || printf '')
    fi
    if [[ -z "$tz" && -L /etc/localtime ]]; then
        tz=$(readlink -f /etc/localtime | sed -n 's|.*/zoneinfo/||p')
    fi
    if [[ -z "$tz" && -f /etc/timezone ]]; then
        tz=$(cat /etc/timezone 2>/dev/null || printf '')
    fi
    if [[ -z "$tz" && -n "${TZ:-}" ]]; then
        tz="$TZ"
    fi

    printf '%s\n' "${tz:-Europe/Rome}"
}

resolve_target_locale() {
    case "$1" in
        Europe/Rome|Europe/San_Marino|Europe/Vatican) printf 'it_IT.UTF-8\n' ;;
        Europe/Paris|Europe/Monaco)                 printf 'fr_FR.UTF-8\n' ;;
        Europe/Berlin)                              printf 'de_DE.UTF-8\n' ;;
        Europe/Vienna)                              printf 'de_AT.UTF-8\n' ;;
        Europe/Zurich)                              printf 'de_CH.UTF-8\n' ;;
        Europe/Madrid|Europe/Andorra)               printf 'es_ES.UTF-8\n' ;;
        Europe/Lisbon)                              printf 'pt_PT.UTF-8\n' ;;
        Europe/Amsterdam)                           printf 'nl_NL.UTF-8\n' ;;
        Europe/Brussels)                            printf 'nl_BE.UTF-8\n' ;;
        Europe/London)                              printf 'en_GB.UTF-8\n' ;;
        Europe/Dublin)                              printf 'en_IE.UTF-8\n' ;;
        Europe/Athens)                              printf 'el_GR.UTF-8\n' ;;
        Europe/Stockholm)                           printf 'sv_SE.UTF-8\n' ;;
        Europe/Oslo)                                printf 'nb_NO.UTF-8\n' ;;
        Europe/Helsinki)                            printf 'fi_FI.UTF-8\n' ;;
        Europe/Copenhagen)                          printf 'da_DK.UTF-8\n' ;;
        Europe/Warsaw)                              printf 'pl_PL.UTF-8\n' ;;
        Europe/Prague)                              printf 'cs_CZ.UTF-8\n' ;;
        Europe/Budapest)                            printf 'hu_HU.UTF-8\n' ;;
        Europe/Bucharest|Europe/Chisinau)           printf 'ro_RO.UTF-8\n' ;;
        Europe/Sofia)                               printf 'bg_BG.UTF-8\n' ;;
        Europe/Zagreb)                              printf 'hr_HR.UTF-8\n' ;;
        Europe/Belgrade)                            printf 'sr_RS.UTF-8\n' ;;
        Europe/Ljubljana)                           printf 'sl_SI.UTF-8\n' ;;
        Europe/Istanbul|Asia/Istanbul)              printf 'tr_TR.UTF-8\n' ;;
        Europe/Kyiv|Europe/Kiev)                    printf 'uk_UA.UTF-8\n' ;;
        America/Sao_Paulo|America/Fortaleza|America/Manaus|America/Bahia|America/Belem|America/Recife|America/Cuiaba|America/Porto_Velho|America/Rio_Branco|America/Boa_Vista|America/Maceio|America/Campo_Grande)
            printf 'pt_BR.UTF-8\n' ;;
        America/Argentina/*|America/Buenos_Aires|America/Cordoba|America/Mendoza|America/Santiago|America/Bogota|America/Lima|America/Caracas|America/Montevideo|America/Asuncion|America/La_Paz)
            printf 'es_419.UTF-8\n' ;;
        America/Mexico_City|America/Cancun|America/Monterrey|America/Tijuana|America/Hermosillo|America/Chihuahua|America/Mazatlan|America/Merida|America/Guatemala|America/El_Salvador|America/Managua|America/Costa_Rica|America/Panama|America/Tegucigalpa)
            printf 'es_MX.UTF-8\n' ;;
        America/New_York|America/Chicago|America/Denver|America/Los_Angeles|America/Phoenix|America/Anchorage|America/Honolulu|America/Detroit|America/Indiana/*|America/Kentucky/*|America/North_Dakota/*|America/Boise)
            printf 'en_US.UTF-8\n' ;;
        America/Montreal)                           printf 'fr_CA.UTF-8\n' ;;
        America/Toronto|America/Vancouver|America/Edmonton|America/Winnipeg|America/Halifax|America/St_Johns|America/Regina)
            printf 'en_CA.UTF-8\n' ;;
        Asia/Tokyo)                                 printf 'ja_JP.UTF-8\n' ;;
        Asia/Seoul)                                 printf 'ko_KR.UTF-8\n' ;;
        Asia/Shanghai|Asia/Chongqing|Asia/Harbin|Asia/Urumqi|Asia/Beijing)
            printf 'zh_CN.UTF-8\n' ;;
        Asia/Taipei)                                printf 'zh_TW.UTF-8\n' ;;
        Asia/Hong_Kong)                             printf 'zh_HK.UTF-8\n' ;;
        Asia/Singapore)                             printf 'en_SG.UTF-8\n' ;;
        Asia/Kolkata|Asia/Calcutta)                 printf 'en_IN.UTF-8\n' ;;
        Asia/Manila)                                printf 'en_PH.UTF-8\n' ;;
        Asia/Dubai|Asia/Riyadh|Asia/Qatar|Asia/Kuwait|Asia/Bahrain|Asia/Muscat)
            printf 'ar_AE.UTF-8\n' ;;
        Asia/Jerusalem|Asia/Tel_Aviv)               printf 'he_IL.UTF-8\n' ;;
        Asia/Bangkok)                               printf 'th_TH.UTF-8\n' ;;
        Asia/Jakarta)                               printf 'id_ID.UTF-8\n' ;;
        Asia/Ho_Chi_Minh|Asia/Saigon)               printf 'vi_VN.UTF-8\n' ;;
        Australia/Sydney|Australia/Melbourne|Australia/Brisbane|Australia/Perth|Australia/Adelaide|Australia/Hobart|Australia/Darwin|Australia/Canberra)
            printf 'en_AU.UTF-8\n' ;;
        Pacific/Auckland)                           printf 'en_NZ.UTF-8\n' ;;
        Africa/Cairo)                               printf 'ar_EG.UTF-8\n' ;;
        Africa/Johannesburg)                        printf 'en_ZA.UTF-8\n' ;;
        Africa/Casablanca|Africa/Algiers|Africa/Tunis)
            printf 'fr_MA.UTF-8\n' ;;
        Europe/*)                                   printf 'it_IT.UTF-8\n' ;;
        *)                                          printf 'en_US.UTF-8\n' ;;
    esac
}

resolve_target_keymap() {
    case "$1" in
        Europe/Rome|Europe/San_Marino|Europe/Vatican) printf 'it\n' ;;
        Europe/Paris|Europe/Monaco|Africa/Casablanca|Africa/Algiers|Africa/Tunis) printf 'fr\n' ;;
        Europe/Berlin|Europe/Vienna)                printf 'de-latin1\n' ;;
        Europe/Zurich)                              printf 'sg-latin1\n' ;;
        Europe/Madrid|Europe/Andorra|America/Argentina/*|America/Buenos_Aires|America/Cordoba|America/Mendoza|America/Santiago|America/Bogota|America/Lima|America/Caracas|America/Montevideo|America/Asuncion|America/La_Paz)
            printf 'es\n' ;;
        Europe/Lisbon)                              printf 'pt-latin1\n' ;;
        America/Sao_Paulo|America/Fortaleza|America/Manaus|America/Bahia|America/Belem|America/Recife|America/Cuiaba|America/Porto_Velho|America/Rio_Branco|America/Boa_Vista|America/Maceio|America/Campo_Grande)
            printf 'br-abnt2\n' ;;
        America/Mexico_City|America/Cancun|America/Monterrey|America/Tijuana|America/Hermosillo|America/Chihuahua|America/Mazatlan|America/Merida|America/Guatemala|America/El_Salvador|America/Managua|America/Costa_Rica|America/Panama|America/Tegucigalpa)
            printf 'la-latin1\n' ;;
        Europe/London|Europe/Dublin)                printf 'uk\n' ;;
        Europe/Warsaw)                              printf 'pl\n' ;;
        Europe/Prague)                              printf 'cz-qwertz\n' ;;
        Europe/Athens)                              printf 'gr\n' ;;
        Europe/Stockholm)                           printf 'sv-latin1\n' ;;
        Europe/Oslo)                                printf 'no-latin1\n' ;;
        Europe/Helsinki)                            printf 'fi\n' ;;
        Europe/Copenhagen)                          printf 'dk-latin1\n' ;;
        Europe/Bucharest|Europe/Chisinau)           printf 'ro\n' ;;
        Europe/Zagreb)                              printf 'croat\n' ;;
        Europe/Belgrade)                            printf 'sr-cyrl\n' ;;
        Europe/Ljubljana)                           printf 'slovene\n' ;;
        Europe/Sofia)                               printf 'bg_bds-utf8\n' ;;
        Europe/Budapest)                            printf 'hu\n' ;;
        Europe/Istanbul|Asia/Istanbul)              printf 'trq\n' ;;
        Europe/Kyiv|Europe/Kiev)                    printf 'ua-utf\n' ;;
        Asia/Tokyo)                                 printf 'jp106\n' ;;
        Asia/Dubai|Asia/Riyadh|Asia/Qatar|Asia/Kuwait|Asia/Bahrain|Asia/Muscat|Africa/Cairo)
            printf 'ara\n' ;;
        Asia/Jerusalem|Asia/Tel_Aviv)               printf 'il\n' ;;
        America/Montreal)                           printf 'cf\n' ;;
        Europe/*)                                   printf 'it\n' ;;
        *)                                          printf 'us\n' ;;
    esac
}

resolve_target_xkb() {
    case "$1" in
        Europe/Rome|Europe/San_Marino|Europe/Vatican|Europe/Zagreb|Europe/Ljubljana) printf 'it\n' ;;
        Europe/Paris|Europe/Monaco|Europe/Brussels|America/Montreal|Africa/Casablanca|Africa/Algiers|Africa/Tunis)
            printf 'fr\n' ;;
        Europe/Berlin|Europe/Vienna|Europe/Zurich)  printf 'de\n' ;;
        Europe/Madrid|Europe/Andorra|America/Argentina/*|America/Buenos_Aires|America/Cordoba|America/Mendoza|America/Santiago|America/Bogota|America/Lima|America/Caracas|America/Montevideo|America/Asuncion|America/La_Paz)
            printf 'es\n' ;;
        Europe/Lisbon)                              printf 'pt\n' ;;
        Europe/London|Europe/Dublin)                 printf 'gb\n' ;;
        Europe/Warsaw|Europe/Prague)                 printf 'pl\n' ;;
        Europe/Athens|Europe/Nicosia)                printf 'gr\n' ;;
        Asia/Dubai)                                  printf 'ae\n' ;;
        America/Sao_Paulo|America/Fortaleza|America/Manaus|America/Bahia|America/Belem|America/Recife|America/Cuiaba|America/Porto_Velho|America/Rio_Branco|America/Boa_Vista|America/Maceio|America/Campo_Grande)
            printf 'br\n' ;;
        America/Mexico_City|America/Cancun|America/Monterrey|America/Tijuana|America/Hermosillo|America/Chihuahua|America/Mazatlan|America/Merida|America/Guatemala|America/El_Salvador|America/Managua|America/Costa_Rica|America/Panama|America/Tegucigalpa)
            printf 'latam\n' ;;
        Europe/*)                                   printf 'it\n' ;;
        *)                                          printf 'us\n' ;;
    esac
}


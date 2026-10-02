#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/i18n.sh"

i18n_init

row() { printf '  %-12s %s\n' "$1" "$(t "$2")"; }

printf '%s\n' "$(t app.title)"
printf '\n'
row setup "make.setup"
row verify "make.verify"
row test "make.test"
row hook "make.hook"
row icons "make.icons"
row theme "make.theme"
row zed "make.zed"
row micro "make.micro"
row nvim "make.nvim"
row yazi "make.yazi"
row cli "make.cli"
row herdr "make.herdr"
row editors "make.editors"
row lang "make.lang"
row i18n-status "make.i18n_status"
row clean "make.clean"
printf '\n'
log "locale.supported" "${I18N_SUPPORTED[*]}"
log "locale.language_active" "$I18N_LANG"

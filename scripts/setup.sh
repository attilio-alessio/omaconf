#!/usr/bin/env bash


SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$PROJECT_DIR"
MODULES_DIR="$SCRIPT_DIR/modules"
LOG="${OMACONF_LOG:-$PROJECT_DIR/setup.log}"

if [[ "${OMACONF_LOG_STDOUT:-0}" -eq 0 ]]; then
    exec > >(tee -a "$LOG") 2>&1
fi
umask 077

set -euo pipefail

source "$SCRIPT_DIR/lib/i18n.sh"

i18n_init

[[ $EUID -eq 0 ]] || err "__root_required"

PRIMARY_USER="${SUDO_USER:-}"
if [[ -z "$PRIMARY_USER" && "${PKEXEC_UID:-}" =~ ^[0-9]+$ ]]; then
    PRIMARY_USER=$(id -nu "$PKEXEC_UID" 2>/dev/null || printf '')
fi
if [[ -z "$PRIMARY_USER" ]] || ! id "$PRIMARY_USER" &>/dev/null; then
    PRIMARY_USER=$(getent group wheel | cut -d: -f4 | cut -d, -f1)
fi
if [[ -z "$PRIMARY_USER" ]] || ! id "$PRIMARY_USER" &>/dev/null; then
    PRIMARY_USER=$(basename "$(find /home -mindepth 1 -maxdepth 1 -type d 2>/dev/null | tail -1)")
fi
id "$PRIMARY_USER" &>/dev/null || err "__cannot_determine_user"

MODULE_FILES=(
    "$MODULES_DIR/00-env.sh"
    "$MODULES_DIR/05-locale.sh"
    "$MODULES_DIR/10-debloat.sh"
    "$MODULES_DIR/20-defaults.sh"
    "$MODULES_DIR/22-portals.sh"
    "$MODULES_DIR/30-theming.sh"
    "$MODULES_DIR/32-omaqt.sh"
    "$MODULES_DIR/33-nvim.sh"
    "$MODULES_DIR/35-shell-plugins.sh"
    "$MODULES_DIR/40-firewall.sh"
    "$MODULES_DIR/50-kernel.sh"
    "$MODULES_DIR/60-auth.sh"
    "$MODULES_DIR/62-keyring.sh"
    "$MODULES_DIR/70-ssh.sh"
    "$MODULES_DIR/80-services.sh"
    "$MODULES_DIR/85-security-stack.sh"
    "$MODULES_DIR/89-battery-charge.sh"
    "$MODULES_DIR/90-hardware-power.sh"
    "$MODULES_DIR/91-suspend-resume.sh"
    "$MODULES_DIR/95-maintenance.sh"
)

for mod in "${MODULE_FILES[@]}"; do
    [[ -f "$mod" ]] || continue
    mod_name=$(basename "$mod")
    log "__stage" "$mod_name"
    # shellcheck disable=SC1090
    source "$mod"
done

log "__complete"

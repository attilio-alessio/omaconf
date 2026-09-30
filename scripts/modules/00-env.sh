set -euo pipefail

log "env.sync"
pacman -Syu --noconfirm 2>/dev/null || warn "env.sync_skipped"

log "env.fixing_broken"
for pkg_dir in /var/lib/pacman/local/*/; do
    [[ -d "$pkg_dir" ]] || continue
    [[ -f "$pkg_dir/desc" ]] || { warn "env.removing_broken" "$pkg_dir"; rm -rf "$pkg_dir"; }
done

aur_verified_install() {
    local pkg="$1" tmp f
    [[ -n "$pkg" ]] || err "env.aur_empty"
    [[ "$pkg" =~ ^[a-zA-Z0-9._-]+$ ]] || err "env.aur_invalid" "$pkg"
    pacman -S --noconfirm --needed base-devel git wget
    tmp=$(mktemp -d)
    chmod 700 "$tmp"
    chown "$PRIMARY_USER":"$PRIMARY_USER" "$tmp"
    sudo -u "$PRIMARY_USER" bash -c \
        "cd '$tmp' && git clone --quiet --depth 1 https://aur.archlinux.org/$pkg.git src && cd src && \
         { grep -q '^validpgpkeys=' PKGBUILD || \
           { grep -qE '^(sha256sums|sha512sums|b2sums|sha256sums_x86_64)=' PKGBUILD && ! grep -q 'SKIP' PKGBUILD && \
             grep -qE '^# Maintainer: [^< ]+ <[^ ]+@[^ ]+>' PKGBUILD; }; }" || \
        err "env.aur_no_integrity" "$pkg"
    sudo -u "$PRIMARY_USER" bash -c \
        "cd '$tmp/src' && makepkg --noconfirm" || {
        rm -rf "$tmp"
        err "env.aur_verify_failed" "$pkg"
    }
    f=$(find "$tmp/src" -name '*.pkg.tar.*' -type f 2>/dev/null | head -1)
    [[ -n "$f" ]] || { rm -rf "$tmp"; err "env.aur_no_artifact" "$pkg"; }
    pacman -U --noconfirm "$f"
    rm -rf "$tmp"
}

user_as() {
    local user="$1"
    shift
    [[ -n "$user" ]] || { warn "env.user_as_no_user"; return 1; }
    local home="" runtime="" bus="" uid=""
    home=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
    [[ -n "$home" ]] || home="/home/$user"
    uid=$(id -u "$user" 2>/dev/null || printf '')
    if [[ -n "$uid" && -d "/run/user/$uid" ]]; then
        runtime="/run/user/$uid"
        bus="unix:path=/run/user/$uid/bus"
    fi
    local -a _env=(
        "HOME=$home"
        "PATH=$home/.local/bin:/usr/share/omarchy/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin"
        "XDG_RUNTIME_DIR=$runtime"
        "DBUS_SESSION_BUS_ADDRESS=$bus"
    )
    if [[ -n "${OMACONF_LANG:-}" ]]; then _env+=("OMACONF_LANG=$OMACONF_LANG"); fi
    if [[ -n "${OMACONF_FORCE_TZ:-}" ]]; then _env+=("OMACONF_FORCE_TZ=$OMACONF_FORCE_TZ"); fi
    sudo -u "$user" env -u XDG_SESSION_DESKTOP -u DESKTOP_SESSION "${_env[@]}" "$@"
}

omarchy_as() {
    local user="$1"
    shift
    [[ -n "$user" ]] || { warn "env.omarchy_as_no_user"; return 1; }
    if [[ -z "${OMARCHY_PATH:-}" ]]; then
        if [[ -f /usr/share/omarchy/default/bash/env-bootstrap ]]; then
            source /usr/share/omarchy/default/bash/env-bootstrap 2>/dev/null || warn "env.omarchy_bootstrap_skipped"
        fi
        OMARCHY_PATH="${OMARCHY_PATH:-/usr/share/omarchy}"
    fi
    user_as "$user" "OMARCHY_PATH=$OMARCHY_PATH" omarchy "$@"
}

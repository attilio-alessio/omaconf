#!/usr/bin/env bash

set -euo pipefail

log "portals.install"
if ! pacman -Q xdg-desktop-portal-termfilechooser &>/dev/null; then
    aur_verified_install xdg-desktop-portal-termfilechooser || warn "portals.termfilechooser_failed"
fi

if ! pacman -Q xdg-desktop-portal-hyprland &>/dev/null; then
    pacman -S --noconfirm --needed xdg-desktop-portal-hyprland 2>/dev/null || warn "portals.hyprland_failed"
fi

log "portals.configure"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _tf_dir="$user_home/.config/xdg-desktop-portal-termfilechooser"
    _portal_dir="$user_home/.config/xdg-desktop-portal"
    mkdir -p "$_tf_dir" "$_portal_dir" 2>/dev/null || warn "portals.dirs_skipped" "$_user"

    cat > "$_tf_dir/config" << 'TFEOF'
[filechooser]
cmd=/usr/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
default_dir=$HOME
env=TERMCMD=kitty --title "termfilechooser"
open_mode=suggested
save_mode=last
TFEOF
    chmod 644 "$_tf_dir/config" 2>/dev/null || warn "portals.config_chmod" "$_user"

    for _pc in portals.conf hyprland-portals.conf; do
        _pf="$_portal_dir/$_pc"
        cat > "$_pf" << 'PORTEOF'
[preferred]
default=hyprland;termfilechooser
org.freedesktop.impl.portal.FileChooser=termfilechooser
org.freedesktop.impl.portal.AppChooser=hyprland;termfilechooser
org.freedesktop.impl.portal.OpenURI=hyprland;termfilechooser
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.Screenshot=hyprland
PORTEOF
        chmod 644 "$_pf" 2>/dev/null || warn "portals.conf_chmod" "$_user"
    done
    chown -R "$_user":"$_user" "$_tf_dir" "$_portal_dir" 2>/dev/null || warn "portals.chown_failed" "$_user"

    user_as "$_user" systemctl --user mask xdg-desktop-portal-gtk.service xdg-desktop-portal-gnome.service 2>/dev/null || warn "portals.mask_skipped" "$_user"
done

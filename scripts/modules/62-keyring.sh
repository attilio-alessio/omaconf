#!/usr/bin/env bash

set -euo pipefail

log "keyring.install"
for pkg in libsecret pass; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" 2>/dev/null || warn "keyring.pkg_failed" "$pkg"
    fi
done

log "keyring.disable_gnome"
systemctl --global mask gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.global_mask_skipped"

for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    user_as "$_user" systemctl --user mask gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.user_mask_skipped" "$_user"
    user_as "$_user" systemctl --user stop gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.stop_skipped" "$_user"

    _auto_dir="$user_home/.config/autostart"
    mkdir -p "$_auto_dir"
    for autostart_name in gnome-keyring-pkcs11.desktop gnome-keyring-secrets.desktop gnome-keyring-ssh.desktop; do
        cat > "$_auto_dir/$autostart_name" << 'AUTOEOF'
[Desktop Entry]
Type=Application
Hidden=true
AUTOEOF
        chmod 644 "$_auto_dir/$autostart_name" 2>/dev/null || warn "keyring.autostart_chmod" "$_user"
    done

    _keyring_cfg_dir="$user_home/.config/python_keyring"
    mkdir -p "$_keyring_cfg_dir"
    cat > "$_keyring_cfg_dir/keyringrc.cfg" << 'KEYRING_CFG'
[backend]
default-keyring=keyring.backends.SecretService.Keyring
KEYRING_CFG
    chmod 644 "$_keyring_cfg_dir/keyringrc.cfg" 2>/dev/null || warn "keyring.cfg_chmod" "$_user"

    chown -R "$_user":"$_user" "$_auto_dir" "$_keyring_cfg_dir" 2>/dev/null || warn "keyring.chown_failed" "$_user"
done

log "keyring.pam_cleanup"
for pam_file in /etc/pam.d/sddm /etc/pam.d/sddm-autologin /etc/pam.d/login /etc/pam.d/passwd; do
    if [[ -f "$pam_file" ]] && grep -q 'pam_gnome_keyring' "$pam_file"; then
        sed -i '/pam_gnome_keyring/d' "$pam_file" 2>/dev/null || warn "keyring.pam_sed_skipped" "$pam_file"
    fi
done

pkill -x gnome-keyring-daemon 2>/dev/null || warn "keyring.stop_skipped" "daemon"

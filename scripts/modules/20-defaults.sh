set -euo pipefail

log "defaults.brave_install"
if ! pacman -Q brave-origin-bin &>/dev/null; then
    aur_verified_install brave-origin-bin || err "defaults.brave_failed"
fi

log "defaults.browser"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    omarchy_as "$_user" default browser brave-origin 2>/dev/null || warn "defaults.browser_skipped_user" "$_user"
done

log "defaults.micro_install"
if ! pacman -Q micro &>/dev/null; then
    pacman -S --noconfirm --needed micro
fi

log "defaults.editor"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'micro\n' > "$user_home/.local/state/omarchy/defaults/editor"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "defaults.editor_state_failed" "$_user"
    if [[ -x "$PROJECT_DIR/microconf/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/microconf/install.sh" 2>/dev/null || warn "defaults.microconf_skipped" "$_user"
    fi
done

log "defaults.yazi_install"
if ! pacman -Q yazi &>/dev/null; then
    pacman -S --noconfirm --needed yazi
fi

log "defaults.kitty_install"
if ! pacman -Q kitty &>/dev/null; then
    pacman -S --noconfirm --needed kitty
fi
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    omarchy_as "$_user" default terminal kitty 2>/dev/null || warn "defaults.terminal_skipped" "$_user"
done

log "defaults.yaziconf"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    if [[ -x "$PROJECT_DIR/yaziconf/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/yaziconf/install.sh" 2>/dev/null || warn "defaults.yaziconf_skipped" "$_user"
    fi
done

log "defaults.trash_install"
if ! pacman -Q trash-cli &>/dev/null; then
    pacman -S --noconfirm --needed trash-cli
fi

log "defaults.imv_install"
if ! pacman -Q imv &>/dev/null; then
    pacman -S --noconfirm --needed imv
fi

log "defaults.mpv_install"
if ! pacman -Q mpv &>/dev/null; then
    pacman -S --noconfirm --needed mpv
fi

log "defaults.zathura_install"
if ! pacman -Q zathura &>/dev/null || ! pacman -Q zathura-pdf-mupdf &>/dev/null; then
    pacman -S --noconfirm --needed zathura zathura-pdf-mupdf
fi

log "defaults.pdf"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    user_as "$_user" xdg-mime default org.pwmt.zathura.desktop application/pdf 2>/dev/null || warn "defaults.pdf_skipped" "$_user"
done

log "defaults.filemanager"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _fm="yazi.desktop"
    if [[ -f "$user_home/.local/share/applications/yazi-terminal.desktop" ]]; then
        _fm="yazi-terminal.desktop"
    fi
    user_as "$_user" xdg-mime default "$_fm" inode/directory 2>/dev/null || warn "defaults.fm_skipped" "$_user"
    user_as "$_user" gio mime inode/directory "$_fm" 2>/dev/null || warn "defaults.fm_gio_skipped" "$_user"
    _mimeapps="$user_home/.config/mimeapps.list"
    if [[ -f "$_mimeapps" ]]; then
        if grep -q '^inode/directory=' "$_mimeapps"; then
            sed -i "s|^inode/directory=.*|inode/directory=$_fm|" "$_mimeapps" 2>/dev/null || warn "defaults.fm_enforce_skipped" "$_user"
        else
            sed -i "/^\[Default Applications\]/a inode/directory=$_fm" "$_mimeapps" 2>/dev/null || warn "defaults.fm_insert_skipped" "$_user"
        fi
        sed -i "s|=org.gnome.Nautilus.desktop|=$_fm|g; s|=org.kde.gwenview.desktop|=imv.desktop|g; s|=org.gnome.Evince.desktop|=org.pwmt.zathura.desktop|g" "$_mimeapps" 2>/dev/null || warn "defaults.fm_stale_skipped" "$_user"
        chown "$_user":"$_user" "$_mimeapps" 2>/dev/null || warn "defaults.fm_mimeapps_chown" "$_user"
    fi
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'yazi\n' > "$user_home/.local/state/omarchy/defaults/file-manager"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "defaults.editor_state_failed" "$_user"
done

log "defaults.portal_install"
if ! pacman -Q xdg-desktop-portal-termfilechooser &>/dev/null; then
    aur_verified_install xdg-desktop-portal-termfilechooser || warn "defaults.portal_failed"
fi

log "defaults.portal_route"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _tf_dir="$user_home/.config/xdg-desktop-portal-termfilechooser"
    _portal_dir="$user_home/.config/xdg-desktop-portal"
    mkdir -p "$_tf_dir" "$_portal_dir" 2>/dev/null || warn "defaults.portal_dirs_skipped" "$_user"
    if [[ ! -f "$_tf_dir/config" ]]; then
        cat > "$_tf_dir/config" << 'TFEOF' 2>/dev/null || warn "defaults.portal_config_skipped" "$_user"
[filechooser]
cmd=yazi-wrapper.sh
default_dir=$HOME
env=TERMCMD='kitty --title "terminal filechooser"'
open_mode=suggested
save_mode=last
TFEOF
    fi
    sed -i "s|TERMCMD='foot |TERMCMD='kitty |" "$_tf_dir/config"
    for _pc in portals.conf hyprland-portals.conf; do
        _pf="$_portal_dir/$_pc"
        if grep -q '^org\.freedesktop\.impl\.portal\.FileChooser=' "$_pf" 2>/dev/null; then
            sed -i 's|^org\.freedesktop\.impl\.portal\.FileChooser=.*|org.freedesktop.impl.portal.FileChooser=termfilechooser|' "$_pf" 2>/dev/null || warn "defaults.portal_conf_enforce" "$_user"
        else
            grep -q '^\[preferred\]' "$_pf" 2>/dev/null || printf '[preferred]\n' >> "$_pf" 2>/dev/null || warn "defaults.portal_conf_header" "$_user"
            printf 'org.freedesktop.impl.portal.FileChooser=termfilechooser\n' >> "$_pf" 2>/dev/null || warn "defaults.portal_conf_insert" "$_user"
        fi
    done
    chown -R "$_user":"$_user" "$_tf_dir" "$_portal_dir" 2>/dev/null || warn "defaults.portal_chown_failed" "$_user"
done

log "defaults.rebind"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _bindings="$user_home/.config/hypr/bindings.lua"
    if [[ -f "$_bindings" ]] && ! grep -q 'omablot-yazi-fm' "$_bindings" 2>/dev/null; then
        cat >> "$_bindings" << 'LUAEOF'

-- omablot-yazi-fm: route Omarchy file manager keys to yazi instead of nautilus
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", "xdg-terminal-exec yazi")
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", "xdg-terminal-exec --dir=\"$(omarchy-cmd-terminal-cwd)\" yazi")
LUAEOF
        chown "$_user":"$_user" "$_bindings" 2>/dev/null || warn "defaults.bindings_chown" "$_user"
    fi
done

log "defaults.image"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    user_as "$_user" xdg-mime default imv.desktop image/png image/jpeg image/gif image/webp 2>/dev/null || warn "defaults.image_skipped" "$_user"
done

log "defaults.media"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    user_as "$_user" xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm audio/mpeg 2>/dev/null || warn "defaults.media_skipped" "$_user"
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'mpv\n' > "$user_home/.local/state/omarchy/defaults/media-player"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "defaults.editor_state_failed" "$_user"
done

log "defaults.podman"
for pkg in podman podman-compose podman-docker slirp4netns; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" || warn "defaults.podman_failed" "$pkg"
    fi
done
systemctl enable podman.socket 2>/dev/null || warn "defaults.podman_socket_skipped"

log "defaults.btop_install"
if ! pacman -Q btop &>/dev/null; then
    pacman -S --noconfirm --needed btop || warn "defaults.btop_failed"
fi

log "defaults.cursors_install"
if ! pacman -Q capitaine-cursors &>/dev/null; then
    pacman -S --noconfirm --needed capitaine-cursors || warn "defaults.cursors_failed"
fi

log "defaults.icons_install"
if ! pacman -Q papirus-icon-theme &>/dev/null; then
    pacman -S --noconfirm --needed papirus-icon-theme || warn "defaults.icons_failed"
fi

log "defaults.btop_theme"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _btop_conf="$user_home/.config/btop/btop.conf"
    if [[ -f "$_btop_conf" ]] && ! grep -q '^color_theme *= *"current"' "$_btop_conf" 2>/dev/null; then
        sed -i 's|^color_theme *= *".*"|color_theme = "current"|' "$_btop_conf" 2>/dev/null || warn "defaults.btop_theme_skipped" "$_user"
        chown "$_user":"$_user" "$_btop_conf" 2>/dev/null || warn "defaults.btop_conf_chown" "$_user"
    fi
done

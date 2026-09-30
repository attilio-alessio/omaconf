set -euo pipefail

DEBLOAT=(
    kdenlive
    obs-studio
    obsidian
    libreoffice-fresh
    chromium
    system-config-printer
    nautilus
    totem
    evince
    eog
    yaru-icon-theme
    dolphin
    okular
    gwenview
    xdg-desktop-portal-kde
    plasma-integration
    breeze
    breeze-gtk
    haruna
    docker
    docker-compose
    gnome-disk-utility
    gnome-themes-extra
    foot
)

log "debloat.start"
INSTALLED_DEBLOAT=()
for pkg in "${DEBLOAT[@]}"; do
    if pacman -Qq "$pkg" 2>/dev/null | grep -qx "$pkg"; then
        INSTALLED_DEBLOAT+=("$pkg")
    fi
done
if [[ ${#INSTALLED_DEBLOAT[@]} -gt 0 ]]; then
    if ! pacman -Rns --noconfirm "${INSTALLED_DEBLOAT[@]}"; then
        warn "debloat.partial_removal"
    fi
fi

log "debloat.manifest"
BASE_MANIFEST=/usr/share/omarchy/install/omarchy-base.packages
if [[ -w "$BASE_MANIFEST" ]]; then
    for pkg in "${DEBLOAT[@]}"; do
        sed -i "/^${pkg}$/d" "$BASE_MANIFEST"
    done
fi

log "debloat.pin"
mkdir -p /etc/pacman.d/omablot
chmod 755 /etc/pacman.d/omablot 2>/dev/null || warn "debloat.omablot_chmod_skipped"
printf '%s\n' "${DEBLOAT[@]}" > /etc/pacman.d/omablot/ignore-pkgs.list
chmod 644 /etc/pacman.d/omablot/ignore-pkgs.list 2>/dev/null || warn "debloat.ignore_chmod_skipped"
EXISTING_PINS=""
if grep -q '^IgnorePkg' /etc/pacman.conf 2>/dev/null; then
    EXISTING_PINS=$(grep '^IgnorePkg' /etc/pacman.conf | head -1 | sed 's/^IgnorePkg[[:space:]]*=[[:space:]]*//')
fi
MERGED_PINS="$EXISTING_PINS"
for pkg in "${DEBLOAT[@]}"; do
    grep -qw "$pkg" <<< " $MERGED_PINS " 2>/dev/null || MERGED_PINS="$MERGED_PINS $pkg"
done
MERGED_PINS=$(echo "$MERGED_PINS" | xargs)
if grep -q '^IgnorePkg' /etc/pacman.conf; then
    sed -i "s|^IgnorePkg.*|IgnorePkg = $MERGED_PINS|" /etc/pacman.conf
else
    sed -i "/^\[options\]/a IgnorePkg = $MERGED_PINS" /etc/pacman.conf
fi

log "debloat.foot_cleanup"
if ! pacman -Q foot &>/dev/null && ! command -v foot &>/dev/null; then
    for u_home in /home/*; do
        [[ -d "$u_home" ]] || continue
        rm -f "$u_home/.local/share/applications/foot.desktop" 2>/dev/null || warn "debloat.foot_skipped" "$u_home"
        rm -f "$u_home/.local/share/applications/footclient.desktop" 2>/dev/null || warn "debloat.footclient_skipped" "$u_home"
        rm -f "$u_home/.local/share/applications/foot-server.desktop" 2>/dev/null || warn "debloat.footserver_skipped" "$u_home"
    done
fi

log "debloat.webapps"
for webapp in Basecamp "Google Contacts" "Google Maps" "Google Messages" "Google Photos" Discord HEY WhatsApp X YouTube Zoom; do
    rm -f "/usr/share/omarchy/applications/$webapp.desktop"
done
if [[ -d /usr/share/omarchy/applications ]]; then
    if app_matches=$(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' /usr/share/omarchy/applications 2>/dev/null); then
        while IFS= read -r app_file; do
            [[ -f "$app_file" ]] && rm -f "$app_file"
        done <<< "$app_matches"
    fi
fi
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    for webapp in Basecamp "Google Contacts" "Google Maps" "Google Messages" "Google Photos" Discord HEY WhatsApp X YouTube Zoom; do
        rm -f "$u_home/.local/share/applications/$webapp.desktop"
    done
    if [[ -d "$u_home/.local/share/applications" ]]; then
        if user_matches=$(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' "$u_home/.local/share/applications" 2>/dev/null); then
            while IFS= read -r app_file; do
                [[ -f "$app_file" ]] && rm -f "$app_file"
            done <<< "$user_matches"
        fi
    fi
done

log "debloat.webapps_hook"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    _u=$(basename "$u_home")
    for hook_kind in pre-refresh-pacman.d post-update.d; do
        mkdir -p "$u_home/.config/omarchy/hooks/$hook_kind"
        if [[ -f "$PROJECT_DIR/hooks/$hook_kind/99-omablot-persist" ]]; then
            cp "$PROJECT_DIR/hooks/$hook_kind/99-omablot-persist" "$u_home/.config/omarchy/hooks/$hook_kind/99-omablot-persist"
            chmod +x "$u_home/.config/omarchy/hooks/$hook_kind/99-omablot-persist"
            chown "$_u":"$_u" "$u_home/.config/omarchy/hooks/$hook_kind/99-omablot-persist" 2>/dev/null || warn "debloat.hook_chown_failed" "$_u"
        fi
    done
done

#!/bin/bash
set -euo pipefail

STALE_BINS=(
    kdenlive
    obs-studio
    obsidian
    libreoffice
    chromium
    system-config-printer
    nautilus
    totem
    evince
    eog
    dolphin
    okular
    gwenview
    haruna
    foot
)

clean_paths_for_user() {
    local u_home="$1"
    local pkg="$2"
    local bin="$3"
    shift 3
    if pacman -Q "$pkg" &>/dev/null; then
        return 0
    fi
    if command -v "$bin" &>/dev/null; then
        return 0
    fi
    local rel=""
    for rel in "$@"; do
        rm -rf "$u_home/$rel" 2>/dev/null || warn "home cleanup skipped: $u_home/$rel"
    done
}

log "Cleaning debloated application leftovers in home directories"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    clean_paths_for_user "$u_home" kdenlive kdenlive .config/kdenlive .config/kdenliverc .local/share/kdenlive .cache/kdenlive
    clean_paths_for_user "$u_home" obs-studio obs .config/obs-studio .cache/obs-studio
    clean_paths_for_user "$u_home" obsidian obsidian .config/obsidian .cache/obsidian
    clean_paths_for_user "$u_home" libreoffice-fresh libreoffice .config/libreoffice
    clean_paths_for_user "$u_home" chromium chromium .config/chromium .cache/chromium
    clean_paths_for_user "$u_home" system-config-printer system-config-printer .config/system-config-printer
    clean_paths_for_user "$u_home" nautilus nautilus .config/nautilus .local/share/nautilus .cache/nautilus
    clean_paths_for_user "$u_home" totem totem .config/totem .local/share/totem .cache/totem
    clean_paths_for_user "$u_home" evince evince .config/evince .local/share/evince .cache/evince
    clean_paths_for_user "$u_home" eog eog .config/eog .local/share/eog .cache/eog
    clean_paths_for_user "$u_home" dolphin dolphin .config/dolphinrc .local/share/dolphin .cache/dolphin
    clean_paths_for_user "$u_home" okular okular .config/okularrc .config/okularpartrc .local/share/okular .cache/okular
    clean_paths_for_user "$u_home" gwenview gwenview .config/gwenviewrc .local/share/gwenview .cache/gwenview
    clean_paths_for_user "$u_home" haruna haruna .config/haruna .local/share/haruna .cache/haruna
done

log "Removing stale desktop launchers for missing binaries"
for u_home in /home/*; do
    [[ -d "$u_home/.local/share/applications" ]] || continue
    for stale in "${STALE_BINS[@]}"; do
        if pacman -Q "$stale" &>/dev/null; then
            continue
        fi
        if command -v "$stale" &>/dev/null; then
            continue
        fi
        while IFS= read -r desktop; do
            [[ -f "$desktop" ]] || continue
            rm -f "$desktop" 2>/dev/null || warn "stale launcher removal skipped: $desktop"
        done < <(grep -rlE "(^|[ /=])$stale([ ;]|$)" "$u_home/.local/share/applications" 2>/dev/null || :)
    done
done

log "Removing leftover omarchy webapp launchers"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    for webapp in Basecamp "Google Contacts" "Google Maps" "Google Messages" "Google Photos" Discord HEY WhatsApp X YouTube Zoom; do
        rm -f "$u_home/.local/share/applications/$webapp.desktop" 2>/dev/null || warn "webapp launcher removal skipped for $u_home"
    done
    if [[ -d "$u_home/.local/share/applications" ]]; then
        while IFS= read -r app_file; do
            [[ -f "$app_file" ]] || continue
            rm -f "$app_file" 2>/dev/null || warn "webapp sweep skipped: $app_file"
        done < <(grep -rlE 'omarchy-(launch-webapp|webapp-handler)' "$u_home/.local/share/applications" 2>/dev/null || :)
    fi
done

log "Pruning old thumbnails and trash"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    if [[ -d "$u_home/.cache/thumbnails" ]]; then
        find "$u_home/.cache/thumbnails" -mindepth 1 -atime +30 -delete 2>/dev/null || warn "thumbnail prune skipped for $u_home"
    fi
    if [[ -d "$u_home/.thumbnails" ]]; then
        find "$u_home/.thumbnails" -mindepth 1 -atime +30 -delete 2>/dev/null || warn "legacy thumbnail prune skipped for $u_home"
    fi
    if [[ -d "$u_home/.local/share/Trash/files" ]]; then
        find "$u_home/.local/share/Trash/files" -mindepth 1 -atime +30 -delete 2>/dev/null || warn "trash files prune skipped for $u_home"
    fi
    if [[ -d "$u_home/.local/share/Trash/info" ]]; then
        find "$u_home/.local/share/Trash/info" -mindepth 1 -atime +30 -delete 2>/dev/null || warn "trash info prune skipped for $u_home"
    fi
done

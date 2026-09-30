set -euo pipefail

NVIM_KEEP=(neovim omarchy-nvim)

log "nvim.unpin"
if [[ -f /etc/pacman.d/omasec/ignore-pkgs.list ]]; then
    for pkg in "${NVIM_KEEP[@]}"; do
        sed -i "/^${pkg}$/d" /etc/pacman.d/omasec/ignore-pkgs.list 2>/dev/null || warn "nvim.ignore_list_unpin_skipped" "$pkg"
    done
fi
if grep -q '^IgnorePkg' /etc/pacman.conf 2>/dev/null; then
    for pkg in "${NVIM_KEEP[@]}"; do
        sed -i "s/^IgnorePkg\(.*\)\b${pkg}\b\(.*\)/IgnorePkg\1\2/; s/  \+/ /g; s/ =  */ = /; s/ *$//" /etc/pacman.conf 2>/dev/null || warn "nvim.pacman_conf_unpin_skipped" "$pkg"
    done
fi

log "nvim.install"
for pkg in "${NVIM_KEEP[@]}"; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" || warn "nvim.pkg_skipped" "$pkg"
    fi
done

log "nvim.provision"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    if [[ -x "$PROJECT_DIR/nvimconf/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/nvimconf/install.sh" 2>/dev/null || warn "nvim.conf_skipped" "$_user"
    fi
done

set -euo pipefail

log "maint.pacman_security"
mkdir -p /etc/pacman.d/hooks
cat > /etc/pacman.d/hooks/99-verify-inserted-keyrings.hook << 'HOOK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = archlinux-keyring

[Action]
Description = Verifying keyring signatures...
When = PostTransaction
Exec = /usr/bin/pacman-key --verify
HOOK
chmod 644 /etc/pacman.d/hooks/99-verify-inserted-keyrings.hook

log "maint.weekly"
mkdir -p /etc/cron.weekly
cat > /etc/cron.weekly/security-audit.sh << 'AUDITEOF'
/usr/bin/lynis --cron system >> /var/log/lynis-audit.log 2>&1
/usr/bin/rkhunter --check --skip-keypress --report-warnings-only >> /var/log/rkhunter-audit.log 2>&1
/usr/bin/freshclam >> /var/log/clamav-update.log 2>&1
AUDITEOF
chmod 755 /etc/cron.weekly/security-audit.sh

log "maint.logs"
cat > /etc/logrotate.d/security << 'LOGROTATE'
/var/log/sudo-io/*
{
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 root adm
    sharedscripts
    postrotate
        /usr/bin/systemctl kill -s HUP systemd-journald 2>/dev/null
    endscript
}
LOGROTATE

log "maint.sudo"
mkdir -p /var/log/sudo
cat > /etc/sudoers.d/security << 'SUDO'
Defaults env_reset,timestamp_timeout=5,passwd_timeout=2
Defaults mail_badpass
Defaults use_pty
Defaults log_input,log_output
Defaults iolog_dir=/var/log/sudo
SUDO
visudo -cf /etc/sudoers.d/security >/dev/null 2>&1 || { rm -f /etc/sudoers.d/security; err "maint.sudoers_invalid"; }
chmod 440 /etc/sudoers.d/security

echo 'Defaults passwd_tries=3' > /etc/sudoers.d/passwd-tries
chmod 440 /etc/sudoers.d/passwd-tries

log "maint.tpm"
if [[ -f /usr/lib/nvpcr/verity.nvpcr ]]; then
    rm -f /usr/lib/nvpcr/verity.nvpcr
fi

log "maint.voxtype"
if ! command -v voxtype &>/dev/null; then
    for u_home in /home/*; do
        [[ -d "$u_home" ]] || continue
        rm -f "$u_home/.config/systemd/user/graphical-session.target.wants/voxtype.service" 2>/dev/null || warn "maint.voxtype_user_skipped" "$u_home"
    done
    if systemctl list-unit-files voxtype.service &>/dev/null; then
        systemctl --global disable voxtype.service 2>/dev/null || warn "maint.voxtype_global_skipped"
    fi
fi

log "maint.profiles"
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    if [[ -f "$u_home/.profile" ]]; then
        sed -i 's|^\. "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"|' "$u_home/.profile"
        sed -i 's|^source "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& source "$HOME/.cargo/env"|' "$u_home/.profile"
    fi
    if [[ -f "$u_home/.bash_profile" ]]; then
        sed -i 's|^\. "\$HOME/\.cargo/env"|[[ -f "$HOME/.cargo/env" ]] \&\& . "$HOME/.cargo/env"|' "$u_home/.bash_profile"
        sed -i 's|^source "\$HOME/\.cargo/env"|[[ -f "$HOME/.cargo/env" ]] \&\& source "$HOME/.cargo/env"|' "$u_home/.bash_profile"
    fi
done

log "maint.orphans"
mapfile -t orphans < <(pacman -Qdtq 2>/dev/null || :)
if [[ ${#orphans[@]} -gt 0 && -n "${orphans[0]}" ]]; then
    pacman -Rns --noconfirm "${orphans[@]}" 2>/dev/null || warn "maint.orphans_skipped"
fi

log "maint.cache"
pacman -Scc --noconfirm 2>/dev/null || warn "maint.cache_skipped"

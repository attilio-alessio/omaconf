set -euo pipefail

log "power.deep_sleep"
if [[ -r /sys/power/mem_sleep ]] && grep -qw deep /sys/power/mem_sleep; then
    mkdir -p /etc/systemd/sleep.conf.d
    chmod 755 /etc/systemd/sleep.conf.d
    cat > /etc/systemd/sleep.conf.d/99-omablot-deep-sleep.conf << 'SLEEP_MODE'
[Sleep]
MemorySleepMode=deep
SLEEP_MODE
    chmod 644 /etc/systemd/sleep.conf.d/99-omablot-deep-sleep.conf
fi

log "power.usb_storage"
cat > /etc/modprobe.d/disable-usb-storage.conf << 'USB'
install usb-storage /bin/true
blacklist usb-storage
USB

log "power.protocols"
cat > /etc/modprobe.d/disable-protocols.conf << 'PROTO'
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
PROTO

log "power.firewire"
cat > /etc/modprobe.d/disable-firewire.conf << 'FIREWIRE'
blacklist firewire-core
blacklist firewire-ohci
blacklist firewire-sbp2
FIREWIRE

log "power.filesystems"
cat > /etc/modprobe.d/disable-ramfs.conf << 'RAMFS'
blacklist cramfs
blacklist freevxfs
blacklist hfs
blacklist hfsplus
blacklist jffs2
blacklist udf
RAMFS

log "power.perms"
chmod 700 /root
chmod 600 /etc/shadow
chmod 600 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group
chmod 750 /etc/ssh
for _ssh_conf in /etc/ssh/ssh_config /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf /etc/ssh/ssh_config.d/*.conf; do
    [[ -f "$_ssh_conf" ]] || continue
    chmod 644 "$_ssh_conf" 2>/dev/null || warn "power.ssh_chmod"
done
for u_home in /home/*; do
    [[ -d "$u_home" ]] || continue
    chmod 750 "$u_home" 2>/dev/null || warn "power.home_chown" "$u_home"
    for d in Documents Downloads Desktop; do
        [[ -d "$u_home/$d" ]] && (chmod 750 "$u_home/$d" 2>/dev/null || warn "power.user_dir_chown" "$u_home" "$d")
    done
done

log "power.shared_mem"
grep -q '^tmpfs /run/shm tmpfs' /etc/fstab || \
    echo "tmpfs /run/shm tmpfs defaults,nosuid,nodev,mode=1777 0 0" >> /etc/fstab

log "power.tmp"
for mount_point in /tmp /var/tmp; do
    if grep -q "^tmpfs $mount_point tmpfs" /etc/fstab; then
        if grep -q "^tmpfs $mount_point tmpfs.*noexec" /etc/fstab; then
            sed -i "s|^tmpfs $mount_point tmpfs.*|tmpfs $mount_point tmpfs defaults,nosuid,nodev,mode=1777 0 0|" /etc/fstab
        fi
    else
        echo "tmpfs $mount_point tmpfs defaults,nosuid,nodev,mode=1777 0 0" >> /etc/fstab
    fi
done

log "power.umask"
cat > /etc/profile.d/umask.sh << 'UMASK'
umask 077
UMASK
chmod 644 /etc/profile.d/umask.sh
mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/99-umask.conf << 'SYSTEMD_UMASK'
[Manager]
UMask=077
SYSTEMD_UMASK

log "power.coredump"
cat > /etc/systemd/coredump.conf << 'COREDUMP'
[Coredump]
Storage=none
ProcessSizeMax=0
COREDUMP
systemctl daemon-reexec 2>/dev/null || warn "power.daemon_reexec_skipped"

log "power.networkmanager"
rm -f /etc/NetworkManager/conf.d/security.conf

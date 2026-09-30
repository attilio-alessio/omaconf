#!/usr/bin/env bash

set -euo pipefail

log "security.install"
SECURITY_PKGS=(
    lynis
    rkhunter
    clamav
    audit
    usbguard
    fail2ban
    apparmor
)
MISSING_PKGS=()
for pkg in "${SECURITY_PKGS[@]}"; do
    if pacman -Si "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" || warn "security.pkg_failed" "$pkg"
    else
        warn "security.pkg_missing" "$pkg"
        MISSING_PKGS+=("$pkg")
    fi
done

log "security.audit"
mkdir -p /etc/audit/rules.d
cat > /etc/audit/rules.d/hardened.rules << 'AUDIT'
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k sudoers
-w /etc/ssh/sshd_config -p wa -k sshd
-w /etc/ufw -p wa -k firewall
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k privilege_escalation
-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k privilege_escalation
-a always,exit -F arch=b64 -S execve -C gid!=egid -F egid=0 -k privilege_escalation
-a always,exit -F arch=b32 -S execve -C gid!=egid -F egid=0 -k privilege_escalation
-w /etc/hosts -p wa -k system-locale
-w /etc/hostname -p wa -k system-locale
-w /etc/sysctl.conf -p wa -k sysctl
-w /etc/modprobe.d -p wa -k modules
-a always,exit -F arch=b64 -S mount -k mount
-a always,exit -F arch=b32 -S mount -k mount
AUDIT
if systemctl list-unit-files auditd.service &>/dev/null; then
    systemctl enable auditd.service || warn "security.audit_enable_skipped"
fi
if systemctl is-active --quiet auditd.service; then
    if command -v augenrules &>/dev/null; then
        if ! augenrules --check &>/dev/null; then
            augenrules --load &>/dev/null || warn "security.audit_load_skipped"
        fi
    else
        auditctl -R /etc/audit/rules.d/hardened.rules 2>/dev/null || warn "security.audit_load_skipped"
    fi
elif systemctl start auditd.service 2>/dev/null; then
    log "security.audit_started"
else
    warn "security.audit_restart_skipped"
fi

log "security.usbguard"
if pacman -Q usbguard &>/dev/null; then
    mkdir -p /etc/usbguard
    usbguard generate-policy > /etc/usbguard/rules.conf || warn "security.usbguard_policy_failed"
    systemctl enable usbguard.service || warn "security.usbguard_enable_failed"
fi

log "security.clamav"
if pacman -Q clamav &>/dev/null; then
    systemctl enable clamav-freshclam.service || warn "security.clamav_freshclam_failed"
    systemctl enable clamav-daemon.service || warn "security.clamav_daemon_failed"
    if pgrep -x freshclam &>/dev/null; then
        log "security.clamav_update_deferred"
    else
        freshclam 2>/dev/null || warn "security.clamav_update_skipped"
    fi
fi

log "security.fail2ban"
if pacman -Q fail2ban &>/dev/null; then
    cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
ignoreip = 127.0.0.1/8 ::1
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 3
FAIL2BAN
    systemctl enable fail2ban.service || warn "security.fail2ban_enable_failed"
fi

log "security.apparmor"
if pacman -Q apparmor &>/dev/null; then
    mkdir -p /etc/apparmor.d
    if command -v limine-update &>/dev/null && bootctl status 2>/dev/null | grep -q 'Product: Limine'; then
        APPARMOR_BOOT_CONF=/etc/limine-entry-tool.d/omaconf-apparmor.conf
        APPARMOR_BOOT_LINE='KERNEL_CMDLINE[default]+=" lsm=landlock,lockdown,yama,integrity,apparmor,bpf"'
        if ! grep -Fxq "$APPARMOR_BOOT_LINE" "$APPARMOR_BOOT_CONF" 2>/dev/null; then
            mkdir -p /etc/limine-entry-tool.d
            printf '%s\n' "$APPARMOR_BOOT_LINE" > "$APPARMOR_BOOT_CONF"
            chmod 644 "$APPARMOR_BOOT_CONF"
            limine-update || warn "security.apparmor_failed"
        fi
    else
        warn "security.apparmor_boot_unsupported"
    fi

    cat > /etc/apparmor.d/usr.bin.sshd << 'SSHD'
#include <tunables/global>

/usr/bin/sshd {

  #include <abstractions/base>
  #include <abstractions/authentication>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>
  #include <abstractions/ssl_certs>

  capability dac_override,
  capability dac_read_search,
  capability setuid,
  capability setgid,
  capability net_bind_service,

  /etc/ssh/** r,
  /etc/ssh/sshd_config.d/** r,
  /etc/nsswitch.conf r,
  /etc/passwd r,
  /etc/group r,
  /etc/shadow r,
  /etc/gshadow r,
  /var/log/* w,
  /var/empty/** rw,
  /var/run/sshd/ rw,
  /run/sshd/ rw,
  /proc/sys/net/ipv4/tcp_max_syn_backlog r,
  /proc/sys/net/core/somaxconn r,
  /dev/log w,
  /run/nscd.pid rw,
  /run/systemd/notify rw,

  deny /home/** w,
  deny /root/** w,
  deny /var/tmp/** rw,
}
SSHD

    cat > /etc/apparmor.d/usr.bin.useradd << 'USERADD'
#include <tunables/global>

/usr/bin/useradd {

  #include <abstractions/base>
  #include <abstractions/nameservice>

  /etc/passwd rw,
  /etc/shadow rw,
  /etc/group rw,
  /etc/gshadow rw,
  /etc/login.defs r,
  /etc/default/** r,
  /etc/skel/** r,
  /home/** rw,
  /var/spool/mail/** rw,

  deny /etc/sudoers r,
  deny /etc/ssh/** r,
}
USERADD

    cat > /etc/apparmor.d/usr.bin.curl << 'CURL'
#include <tunables/global>

/usr/bin/curl {

  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>
  #include <abstractions/ssl_certs>

  network inet stream,
  network inet6 stream,
  network unix stream,

  /etc/ssl/** r,
  /etc/ca-certificates/** r,
  /etc/resolv.conf r,
  /etc/hosts r,
  /dev/null rw,
  /dev/urandom r,
  /tmp/** rw,

  deny /etc/shadow r,
  deny /etc/gshadow r,
  deny /etc/sudoers r,
  deny /etc/ssh/sshd_config r,
}
CURL

    cat > /etc/apparmor.d/usr.bin.wget << 'WGET'
#include <tunables/global>

/usr/bin/wget {

  #include <abstractions/base>
  #include <abstractions/nameservice>
  #include <abstractions/openssl>
  #include <abstractions/ssl_certs>

  network inet stream,
  network inet6 stream,

  /etc/ssl/** r,
  /etc/ca-certificates/** r,
  /etc/resolv.conf r,
  /etc/hosts r,
  /dev/null rw,
  /dev/urandom r,
  /tmp/** rw,

  deny /etc/shadow r,
  deny /etc/gshadow r,
  deny /etc/sudoers r,
  deny /etc/ssh/sshd_config r,
}
WGET

    chmod 644 \
        /etc/apparmor.d/usr.bin.sshd \
        /etc/apparmor.d/usr.bin.useradd \
        /etc/apparmor.d/usr.bin.curl \
        /etc/apparmor.d/usr.bin.wget

    systemctl enable apparmor.service || warn "security.apparmor_failed"
    aa-enforce /usr/bin/sshd 2>/dev/null || warn "security.aa_sshd"
    aa-enforce /usr/bin/useradd 2>/dev/null || warn "security.aa_useradd"
    aa-enforce /usr/bin/curl 2>/dev/null || warn "security.aa_curl"
    aa-enforce /usr/bin/wget 2>/dev/null || warn "security.aa_wget"
fi

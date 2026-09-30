#!/usr/bin/env bash

set -euo pipefail

log "ssh.secure"
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/hardened.conf << 'SSH'
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KbdInteractiveAuthentication no
MaxAuthTries 3
MaxSessions 4
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
PermitUserEnvironment no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
StrictModes yes
UsePrivilegeSeparation sandbox
AuthenticationMethods publickey
ChrootDirectory none
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
SSH
chmod 600 /etc/ssh/sshd_config.d/hardened.conf

log "ssh.client"
mkdir -p /etc/ssh/ssh_config.d
cat > /etc/ssh/ssh_config.d/hardened.conf << 'SSH_CLIENT'
Host *
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
    HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
SSH_CLIENT
chmod 644 /etc/ssh/ssh_config.d/hardened.conf

if systemctl is-active sshd 2>/dev/null | grep -q active; then
    systemctl restart sshd || warn "ssh.restart_failed"
fi

log "ssh.service"
mkdir -p /etc/systemd/system/sshd.service.d
chmod 755 /etc/systemd/system/sshd.service.d 2>/dev/null || warn "ssh.chmod_skipped"
cat > /etc/systemd/system/sshd.service.d/hardened.conf << 'SSHD_SVC'
[Service]
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
RestrictSUIDSGID=yes
ReadWritePaths=/etc/ssh /var/log /var/run/sshd /run/sshd
SSHD_SVC
chmod 644 /etc/systemd/system/sshd.service.d/hardened.conf 2>/dev/null || warn "ssh.conf_chmod"

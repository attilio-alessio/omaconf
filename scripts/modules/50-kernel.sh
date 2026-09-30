set -euo pipefail

log "kernel.hardening"
cat > /etc/sysctl.d/99-security.conf << 'SYSCTL'
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 3
kernel.unprivileged_bpf_disabled = 1
kernel.yama.ptrace_scope = 1
kernel.core_uses_pid = 1
kernel.sysrq = 16
kernel.io_uring_disabled = 2
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
fs.file-max = 2000000
fs.inotify.max_user_watches = 524288
vm.mmap_rnd_bits = 28
vm.mmap_rnd_compat_bits = 14
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.ip_forward = 0
net.core.bpf_jit_harden = 2
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
SYSCTL
sysctl --system || warn "kernel.sysctl_partial"

cat > /etc/sysctl.d/99-lockdown.conf << 'LOCKDOWN'
kernel.kexec_load_disabled = 1
LOCKDOWN
sysctl --system >/dev/null 2>&1 || warn "kernel.sysctl_partial"

log "kernel.coredump"
mkdir -p /etc/security/limits.d
chmod 755 /etc/security/limits.d 2>/dev/null || warn "kernel.limits_chmod"
cat > /etc/security/limits.d/99-no-core.conf << 'CORE'
* hard core 0
* soft core 0
CORE
chmod 644 /etc/security/limits.d/99-no-core.conf 2>/dev/null || warn "kernel.limits_nocore_chmod"
mkdir -p /etc/systemd/system.conf.d
chmod 755 /etc/systemd/system.conf.d 2>/dev/null || warn "kernel.sysctl_chmod"
printf '[Manager]\nDefaultLimitCORE=0\n' > /etc/systemd/system.conf.d/99-no-core.conf
chmod 644 /etc/systemd/system.conf.d/99-no-core.conf 2>/dev/null || warn "kernel.sysctl_nocore_chmod"

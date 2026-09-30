---
name: arch-hardening
description: >-
  Procedures for managing Arch Linux kernel sysctl hardening, UFW firewall configuration, PAM authentication limits, and tmpfs mount security.
---

# Arch Linux Hardening

## Overview
This skill provides instructions for applying and maintaining kernel parameters, firewall rules, memory protections, and PAM authentication policies on Arch Linux systems running Omarchy.

## Kernel Hardening Configuration
Kernel sysctl parameters are persisted in `/etc/sysctl.d/99-security.conf`. Memory protections enforce full Address Space Layout Randomization with `kernel.randomize_va_space = 2`, hide kernel pointers via `kernel.kptr_restrict = 2`, restrict dmesg buffer access to root using `kernel.dmesg_restrict = 1`, disable unprivileged performance events with `kernel.perf_event_paranoid = 3`, block unprivileged eBPF execution via `kernel.unprivileged_bpf_disabled = 1`, restrict ptrace debugging with `kernel.yama.ptrace_scope = 1`, and restrict SysRq to sync operations via `kernel.sysrq = 16`.

## Filesystem Protection
Filesystem integrity settings prevent setuid core dumps with `fs.suid_dumpable = 0`, block hardlink attacks with `fs.protected_hardlinks = 1`, block symlink traversal attacks with `fs.protected_symlinks = 1`, and restrict FIFO and regular file creation in world-writable sticky directories using `fs.protected_fifos = 2` and `fs.protected_regular = 2`.

## Network Stack Protections
Network protections enforce reverse path filtering with `net.ipv4.conf.all.rp_filter = 1`, reject ICMP redirects using `net.ipv4.conf.all.accept_redirects = 0` and `net.ipv4.conf.all.send_redirects = 0`, reject source routed packets with `net.ipv4.conf.all.accept_source_route = 0`, ignore ICMP broadcast echo requests using `net.ipv4.icmp_echo_ignore_broadcasts = 1`, enable TCP SYN cookies with `net.ipv4.tcp_syncookies = 1`, and prevent TIME-WAIT hazards using `net.ipv4.tcp_rfc1337 = 1`.

## Firewall Management
The UFW firewall operates with default deny incoming and default allow outgoing rules. Verification is executed using `ufw status verbose` and boot enablement is asserted via `systemctl is-enabled ufw.service`. Firewall rule definitions persist in `/etc/ufw/user.rules` and `/etc/ufw/after.rules`.

## PAM and Authentication
Authentication policies enforce lockout after five consecutive failed attempts for 900 seconds in `/etc/security/faillock.conf`. Password complexity is mandated in `/etc/security/pwquality.conf`. User access control lists are defined in `/etc/security/access.conf` and core dump limits are disabled in `/etc/security/limits.d/99-no-core.conf`.

## Hardware and Battery Power Management
Battery health protection enforces a perpetual 75% charge limit across all present and future batteries (`BAT*`, `BATT*`). Policy is defined in `/etc/omaconf/power.conf` (`BATTERY_CHARGE_LIMIT=75`). Persistence across boots, kernel updates, hotplugs, and suspend/resume cycles is guaranteed through triple-layer automation:
- Udev rules in `/etc/udev/rules.d/98-battery-charge-threshold.rules` intercept device creation and power supply changes.
- Systemd-tmpfiles drop-in in `/etc/tmpfiles.d/battery-charge-threshold.conf` applies sysfs thresholds at early boot (`w- /sys/class/power_supply/BAT*/charge_control_end_threshold`).
- Systemd service `battery-charge-threshold.service` re-applies the policy on boot and sleep/resume transitions (`suspend.target`, `hibernate.target`, `hybrid-sleep.target`).

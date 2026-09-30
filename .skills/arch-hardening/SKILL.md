---
name: arch-hardening
description: >-
  Procedures for managing Arch Linux kernel sysctl hardening, UFW firewall configuration, PAM authentication limits, and battery power policy.
---

# Arch Linux Hardening

## Overview
This skill provides instructions for applying and maintaining kernel parameters, firewall rules, memory protections, authentication policies and battery power policy on Arch Linux systems running Omarchy. Every value lives in exactly one drop-in under `/etc`, so a change is applied by rewriting that file rather than by editing live state.

## Kernel Hardening Configuration
Kernel sysctl parameters are persisted in `/etc/sysctl.d/99-security.conf`. Memory protections enforce full address space layout randomization, hide kernel pointers, restrict dmesg buffer access to root, disable unprivileged performance events, block unprivileged eBPF execution, restrict ptrace debugging and limit SysRq to emergency sync operations.

## Filesystem Protection
Filesystem integrity settings prevent setuid core dumps, block hardlink and symlink traversal attacks, and restrict FIFO and regular file creation inside world writable sticky directories.

## Network Stack Protections
Network protections enforce reverse path filtering, reject ICMP redirects in both directions, reject source routed packets, ignore ICMP broadcast echo requests, enable TCP SYN cookies and harden against TIME_WAIT hazards.

## Firewall Management
The UFW firewall operates with a default deny incoming and default allow outgoing policy. Verification is executed with the firewall status command and boot enablement is asserted through the service unit. Rule definitions persist in the user and after rule files owned by the firewall package.

## PAM and Authentication
Authentication policies enforce account lockout after a configured number of consecutive failed attempts for a fixed duration in `/etc/security/faillock.conf`. Password complexity is mandated in `/etc/security/pwquality.conf`. User access control lists are defined in `/etc/security/access.conf` and core dump limits are disabled in `/etc/security/limits.d/99-no-core.conf`.

## Hardware and Battery Power Management
Battery health protection enforces a perpetual charge limit across every present and future battery, matching both the `BAT*` and `BATT*` sysfs naming. The policy value is defined in `/etc/omaconf/power.conf` and persistence is guaranteed through three cooperating layers, because no single mechanism survives every path a battery change can take. Udev rules in `/etc/udev/rules.d/98-battery-charge-threshold.rules` intercept device creation and power supply changes. A systemd-tmpfiles drop-in in `/etc/tmpfiles.d/battery-charge-threshold.conf` applies the sysfs threshold at early boot. A systemd service re-applies the policy on boot and across suspend, hibernate and hybrid sleep targets, and a resume hook covers the case where the kernel rewrites the threshold while the session is suspended.

When writing these layers, keep the threshold in one place and have every layer read it, so changing the policy never requires touching three files. Apply the setting only to batteries that expose the threshold control, and let unsupported hardware through untouched.

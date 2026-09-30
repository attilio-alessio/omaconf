---
name: security-audit-tooling
description: >-
  Procedures for managing auditd rules, fail2ban jails, USBGuard policies, ClamAV virus scanning, and Lynis security scans.
---

# Security Audit Tooling

## Overview
This skill outlines how to maintain, configure, and verify host-based intrusion detection, peripheral device authorization, malware scanning, and automated system security audits on Arch Linux.

## Audit Framework Management
The Linux Audit daemon is configured through `/etc/audit/auditd.conf` while granular kernel audit rules reside in `/etc/audit/rules.d/`. Audit event logs are queried using `ausearch` and aggregated summary reports are generated using `aureport`. Daemon operational state is checked via `systemctl status auditd.service`.

## Intrusion Prevention with Fail2ban
Intrusion detection parameters are configured in `/etc/fail2ban/jail.local`. Active jails are monitored using `fail2ban-client status`, while banned IP addresses for specific services are reviewed with `fail2ban-client status sshd`.

## USB Device Authorization
Peripheral device authorization is enforced through the policy configuration file `/etc/usbguard/rules.conf`. The daemon blocks unauthorized USB storage and rogue devices while allowing recognized human interface input devices such as keyboards and mice. Connected USB hardware states are inspected using `usbguard list-devices`.

## Antivirus and Security Audits
ClamAV signature updates run continuously via `freshclam.service` and the virus scanning engine runs under `clamav-daemon.service`. Manual directory scans are launched with `clamscan -r -i /home`. Comprehensive system auditing is scheduled weekly via `/etc/cron.weekly/security-audit.sh`. Manual audit reports are generated using `lynis audit system` and rootkit integrity checks are run with `rkhunter --check --sk`.

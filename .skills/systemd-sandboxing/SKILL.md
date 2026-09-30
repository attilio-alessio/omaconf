---
name: systemd-sandboxing
description: >-
  Procedures for hardening systemd services with isolation directives, filesystem protections, and capability restrictions.
---

# Systemd Sandboxing

## Overview
This skill outlines how to configure systemd drop-in hardening units to isolate services from unauthorized access to the host filesystem, home directories, and system capabilities.

## Hardening Drop-in Structure
Service isolation overrides are persisted within drop-in configuration units at `/etc/systemd/system/<unit>.service.d/hardened.conf`.

## Isolation Directives
Filesystem protections include mounting `/usr`, `/boot`, and `/etc` read-only via `ProtectSystem=strict` and masking user spaces with `ProtectHome=yes`. Privilege escalation is blocked via `NoNewPrivileges=yes`. Isolated namespace allocation is enabled using `PrivateTmp=yes` and hardware device masking is enforced with `PrivateDevices=yes`. Kernel parameter modifications are blocked with `ProtectKernelTunables=yes` and kernel module loading is prevented by `ProtectKernelModules=yes`. Control groups are protected with `ProtectControlGroups=yes`. Network communication is restricted via `RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6` and namespace creation is restricted with `RestrictNamespaces=yes`. Memory protections prevent writable executable memory allocations with `MemoryDenyWriteExecute=yes`.

## Deployment and Verification
After placing or updating the configuration drop-in file, the systemd manager state is reloaded using `systemctl daemon-reload` and the target service is restarted with `systemctl restart <unit>.service`. The overall security exposure score and directive compliance are inspected using `systemd-analyze security <unit>.service`.

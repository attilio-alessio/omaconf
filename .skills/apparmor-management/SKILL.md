---
name: apparmor-management
description: >-
  Procedures for managing, enforcing, auditing, and troubleshooting AppArmor Mandatory Access Control profiles.
---

# AppArmor Management

## Overview
This skill covers profile lifecycle management, enforcement verification, and log auditing for AppArmor mandatory access control profiles protecting system utilities and services.

## Profile Locations and Target Binaries
Active AppArmor profiles reside in `/etc/apparmor.d/`. Dedicated security profiles managed in omablot enforce confinement rules on sshd, useradd, curl, and wget.

## Status Verification and Mode Control
Enforcement status across loaded profiles is checked using the `aa-status` utility or by querying the `/sys/kernel/security/apparmor/profiles` pseudo-filesystem. Individual profiles are switched into enforce mode with `aa-enforce /etc/apparmor.d/<profile>` or complain mode with `aa-complain /etc/apparmor.d/<profile>`. Profile definitions are reloaded into the kernel with `apparmor_parser -r /etc/apparmor.d/<profile>`.

## Audit Analysis and Profile Tuning
AppArmor kernel denial logs are inspected using `dmesg | grep -i apparmor` or by querying audit logs with `ausearch -m avc -ts recent`. Profile refinements and rule additions are generated interactively from recorded audit events using `aa-logprof`.

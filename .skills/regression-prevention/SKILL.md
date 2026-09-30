---
name: regression-prevention
description: >-
  Procedures and rules to strictly prevent system regressions, including service blockages, daemon failures, and double or frozen lockscreen issues in Omarchy.
---

# Regression Prevention and Desktop Stability

## Overview
This skill establishes strict operational standards and safety requirements to ensure that security hardening, package debloating, and system configurations never introduce functional regressions. Hardening policies must never break essential system services, desktop user sessions, authentication flows, or display locking mechanisms.

## Core Services Protection
System hardening policies, sandboxing directives, and access rules must preserve the integrity and accessibility of critical desktop and system services:
- **Session Bus and IPC**: D-Bus user session (`$DBUS_SESSION_BUS_ADDRESS` and `/run/user/$UID/bus`) must remain reachable. Do not apply sandbox restrictions or environment overrides that strip session bus variables.
- **Authorization & Privileges**: Polkit (`polkit.service`) must remain enabled and functional to permit desktop privilege escalation dialogs.
- **Audio Stack**: PipeWire and WirePlumber (`pipewire.service`, `pipewire-pulse.service`, `wireplumber.service`) must not be restricted or deprived of real-time scheduling permissions.
- **Network Stack**: NetworkManager (`NetworkManager.service`) configuration must not be overridden with conflicting drop-ins (e.g., avoid creating `/etc/NetworkManager/conf.d/security.conf` or breaking DNS resolution).
- **Display Managers & Greeters**: GDM, SDDM, LightDM, and greetd must be explicitly allowed in `/etc/security/access.conf` (e.g., `+:gdm:LOCAL`, `+:sddm:LOCAL`, `+:greetd:LOCAL`, `+:lightdm:LOCAL`) to prevent authentication lockout at boot.
- **User Runtime Directories**: Never alter ownership, sticky permissions, or mount parameters of `/run/user/$UID` in ways that break user service sockets.

## Lockscreen Regression Prevention
Double lockscreens, frozen lockscreens, and unresponsive blank screen overlays represent severe UX and security failures. The following rules must be enforced:
- **Single Canonical Lockscreen Handler**: Only one lockscreen mechanism (such as `hyprlock`, `swaylock`, or `gtklock`) may be active per session. Never configure concurrent locker daemons or duplicate locker calls across idle monitors (e.g., `swayidle`, `hypridle`) and systemd sleep inhibitors.
- **No Unresponsive/Fake Lock Overlays**: Ensure locker processes are properly bound to the active Wayland/X11 compositor session. Never spawn unmanaged background overlays or dummy screens that lack input handling or active authentication backends.
- **PAM Stack Compatibility**: Ensure PAM configurations (`/etc/pam.d/system-auth`, `/etc/pam.d/hyprlock`, etc.) and `faillock` settings do not cause authentication deadlocks or endless unlock loop failures.
- **Input Device Authorization**: USBGuard rules must explicitly allow HID input interfaces (`03:*:*`) so that keyboards and mice remain functional on the lockscreen.
- **Clean Lock-Before-Sleep**: Session lock commands dispatched prior to suspend must synchronize cleanly and avoid spawning orphan background processes that persist after resume.

## Hardening and Sandboxing Boundaries
- **Systemd Drop-ins**: Sandboxing directives such as `ProtectHome`, `ProtectSystem`, `PrivateTmp`, and `RestrictedAddressFamilies` must only be applied to standalone daemons (e.g., `sshd.service`). Never apply blanket sandboxing to user session services, compositor units, or desktop notification services.
- **AppArmor Profiles**: Profiles must be tested and verified to ensure required IPC sockets, cryptographic libraries, and configuration paths remain readable. Never enforce profiles on desktop session components without explicit allowance for Wayland/X11 socket access.
- **Kernel sysctl Safety**: Kernel parameters must preserve standard IPC, shared memory (`/run/shm`), and local socket communications required by desktop applications.

## Verification Workflow
Before and after applying any modification:
1. Run `bash scripts/test-omarchy-compat.sh` to assert that desktop session services, audio, D-Bus, network, and package parity remain fully intact.
2. Run `bash scripts/verify.sh` to validate that security controls are applied without causing state drift or failures.
3. Verify that all scripts execute idempotently without side effects or unhandled error traps.

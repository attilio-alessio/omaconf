---
name: regression-prevention
description: >-
  Procedures and rules to strictly prevent system regressions, including service blockages, daemon failures, and double or frozen lockscreen issues in Omarchy.
---

# Regression Prevention and Desktop Stability

## Overview
This skill establishes strict operational standards and safety requirements so that security hardening, package debloating and system configuration never introduce functional regressions. Hardening policies must never break essential system services, desktop user sessions, authentication flows or display locking mechanisms. A lockdown that makes the desktop unusable is a failed lockdown.

## Core Services Protection
System hardening policies, sandboxing directives and access rules must preserve the integrity and accessibility of the services a live session depends on. The D-Bus user session must stay reachable, so never apply sandbox restrictions or environment overrides that strip the session bus variables or the user runtime directory. The authorization service must remain enabled and functional so the desktop can still ask for privilege escalation. The audio stack must not be restricted or deprived of its real time scheduling permissions. Network manager configuration must never be shadowed by a conflicting drop-in, and DNS resolution must keep working. Every display manager and greeter must be explicitly allowed in the access control configuration so a boot cannot lock the user out. Never alter the ownership, sticky permissions or mount parameters of the user runtime directory in ways that break user service sockets.

## Lockscreen Regression Prevention
Double lockscreens, frozen lockscreens and unresponsive blank screen overlays are severe user experience and security failures. Only one lockscreen mechanism may be active per session, so never configure concurrent locker daemons or duplicate locker calls across the idle monitor and the sleep inhibitor. A locker must be properly bound to the active compositor session, so never spawn unmanaged background overlays or dummy screens that lack input handling or a real authentication backend. PAM configurations and the faillock settings must not cause authentication deadlocks or an endless unlock loop. USBGuard rules must explicitly allow human interface device interfaces so keyboards and mice remain usable on the lockscreen. A lock command dispatched before suspend must synchronize cleanly and must not leave orphan processes behind after resume.

## Hardening and Sandboxing Boundaries
Sandboxing directives belong only on standalone daemons such as the SSH daemon. Never apply blanket sandboxing to user session services, compositor units or desktop notification services. AppArmor profiles must be tested so the required IPC sockets, cryptographic libraries and configuration paths stay readable, and must never be enforced on desktop session components without an explicit allowance for the display server sockets. Kernel parameters must preserve standard interprocess communication, shared memory and local socket behaviour that desktop applications rely on.

## Verification Workflow
Before and after any modification, run the compatibility suite to assert that desktop session services, audio, the session bus, the network and package parity remain intact. Run the verifier to confirm the security controls are applied without state drift. Confirm that every script executes idempotently and that no failure is silently swallowed. Both suites run in continuous integration, so a change that regresses the desktop fails the build rather than the user's session.

---
name: idempotent-bash-automation
description: >-
  Procedures and coding standards for authoring safe, idempotent Bash scripts, verification suites, and foreground execution pipelines.
---

# Idempotent Bash Automation

## Overview
This skill defines standards and procedures for authoring safe, predictable, and idempotent Bash administration scripts, testing harnesses, and verification suites within omaconf.

## Native Scripting Standards
Scripts must use strict shell flags `set -euo pipefail` without Python runtimes or external script dependencies. Never use `|| true` to suppress return codes. Use `|| warn "message"` exclusively for non-critical steps that are intentionally permitted to continue upon failure. Avoid background execution or `systemd-run`; all automation steps must run synchronously in the foreground with direct stdout logging. User paths must never be hardcoded and must be derived dynamically from `$HOME` or `/home/*`.

## Idempotency and State Management
Every script operation must verify the current system state prior to making mutations. Operations modifying configuration files such as `/etc/pacman.conf` or PAM files must detect existing directives to avoid creating duplicate configuration entries. Multiple successive executions of any script must result in an identical, stable system configuration.

## Verification and Testing
Automated verification assertions are implemented in `scripts/verify.sh` and compatibility tests are executed in `scripts/test-omarchy-compat.sh`. Verification scripts maintain explicit pass and fail counters and return a non-zero exit code whenever any failure condition is encountered.

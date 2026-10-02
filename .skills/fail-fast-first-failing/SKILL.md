---
name: fail-fast-first-failing
description: >-
  Procedures and standards for enforcing the fail-fast and first-failing principle: eliminating silent failures, banning unhandled error suppressions, and ensuring immediate visibility on errors.
---

# Fail-Fast and First-Failing Principle

## Overview
This skill defines the engineering discipline and standards for building software that fails immediately and visibly at the earliest point of error. In robust systems automation and security hardening, silent failures, swallowed exit codes, and unchecked assumptions mask underlying defects, corrupt system state, and impede diagnostics. Every operation must either succeed cleanly or fail loudly and informatively.

## Core Tenets
1. **First-Failing Detection**: A failure must be captured at the very first instruction that encounters an unexpected condition, preventing cascaded or corrupted downstream states.
2. **Zero Silent Failures**: Commands must never suppress failures silently. Blanket catch-alls like `|| true`, `|| null`, or unmonitored redirects to `/dev/null` without explicit fallback handling or error reporting are strictly forbidden.
3. **Explicit Error Boundaries**: Differentiate between fatal errors that must halt execution (`err`) and non-critical operations that are intentionally allowed to degrade gracefully (`warn`). Every graceful degradation must emit a structured, localized diagnostic log.
4. **Deterministic Exit Codes**: All subshells, pipelines, and helper functions must propagate exit statuses accurately. Pipelines must always execute under `set -euo pipefail`.

## Implementation Rules
- Always use `set -euo pipefail` in shell scripts.
- Never use `|| true` to mask errors; use `|| warn "message.key"` for optional degradation with diagnostic output, or `|| err "message.key"` for fatal requirements.
- Avoid unchecked command substitution and silent redirection of stderr unless the output is explicitly validated by a condition.
- When validating package states, file paths, or service statuses, perform explicit state checks (e.g., `pacman -Q`, `systemctl is-active`, `[[ -f ... ]]`) before executing mutations.
- Ensure all subprocess invocations, terminal wrappers, and IPC channels preserve and propagate standard error streams.

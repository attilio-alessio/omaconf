---
name: privacy-shield
description: >-
  Procedures for shoulder-surfing protection on Omarchy - gated yazi previews and enforced idle lock.
---

# Privacy Shield

## Overview

This skill defines how the obscure microcomponent protects sensitive content from prying eyes. The yazi gate replaces previews of 2FA backup codes, recovery keys, passwords, and secrets with a lock screen and routes opening through a password check. The idle stage enforces the native Omarchy blank and lock chain. Everything is idempotent and degrades to warnings.

## Yazi Gate Standards

Keep the sensitive filename globs in `data/patterns`: 2FA and authenticator names first, then recovery and backup codes, then passwords, secrets, credentials, key material, and encrypted stores. Every pattern must be registered in all three places per user: `prepend_previewers` running the `obscure` plugin, `[open] prepend_rules` using the `obscure-view` opener, and `[icon] prepend_globs` with a red lock icon. The plugin renders only the lock screen and never the file content. The opener prompts for the system login password and verifies it through `sudo -S -v`, dropping the timestamp with `sudo -k` immediately afterwards, before paging text, viewing PDF documents, or delegating other types. TOML edits stay inside marker blocks so they are idempotent and detectable by verification. Setup elevates with `pkexec`. After the debloat microcomponent reinstalls yazi configuration, re-run obscure setup to restore the gate.

## Idle Obscure Standards

Remove the stay-awake indicator and the screensaver-off toggle per user so the Omarchy defaults apply: screensaver after 150 seconds, lock after 300 seconds. Never ship a custom locker or idle daemon: the canonical Omarchy lockscreen is the only session lock.

## Agent Workflow

Agents working in this repository diagnose first by reading the stage modules together with the verification script and the test suite. Changes stay minimal and idempotent under strict shell flags with graceful warnings for non-critical steps. Lua plugin changes are syntax-checked with `luac -p` and generated TOML blocks are validated with `tomllib`. Every change is validated with the full test suite and the verification script before any commit, and commits follow the Conventional Commits format defined in `AGENTS.md`.

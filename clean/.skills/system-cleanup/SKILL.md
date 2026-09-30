---
name: system-cleanup
description: >-
  Procedures for safe general system cleanup and post-debloat home hygiene on Omarchy.
---

# System Cleanup

## Overview

This skill defines how the clean microcomponent keeps the machine lean after debloat without ever risking user data. System stages handle cache, orphans, journals, temp files, and unused runtimes. Home stages handle per-user leftovers of removed applications, stale launchers, webapps, thumbnails, and old trash. Everything is idempotent and degrades to warnings.

## System Hygiene Standards

Trim the pacman cache to two kept versions with `paccache -rk2`, falling back to `pacman -Sc` when paccache is absent. Remove orphans discovered via `pacman -Qtdq` with `pacman -Rns`. Vacuum the journal to 200M and two weeks. Prune coredumps older than 14 days. Remove top-level `/tmp` entries older than 7 days and `/var/tmp` entries older than 14 days. Drop unused flatpak runtimes only when flatpak exists. Refresh font caches. Never pin, install, or force-remove packages owned by sibling microcomponents.

## Home Hygiene Standards

Iterate `/home/*` with directory guards and never hardcode usernames. For each debloated application, remove its `.config`, `.local/share`, and `.cache` paths only when both `pacman -Q <pkg>` and `command -v <bin>` fail, so present applications are untouched. Sweep `.local/share/applications` for `.desktop` files referencing missing binaries and for `omarchy-launch-webapp` leftovers. Prune `.cache/thumbnails` and `.thumbnails` entries older than 30 days. Prune `Trash/files` and `Trash/info` entries older than 30 days. Never touch vaults, documents, or editor configs.

## Agent Workflow

Agents working in this repository diagnose first by reading the stage modules together with the verification script and the test suite. Changes stay minimal and idempotent under strict shell flags with graceful warnings for non-critical steps. Every change is validated with the full test suite and the verification script before any commit, and commits follow the Conventional Commits format defined in `AGENTS.md`.

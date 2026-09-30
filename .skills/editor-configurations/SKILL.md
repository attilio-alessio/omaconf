---
name: editor-configurations
description: >-
  Procedures and standards for managing, installing, and synchronizing native configurations for Zed and Micro editors in Omarchy.
---

# Editor Configurations

## Overview
This skill provides guidelines and procedures for maintaining modular native configurations for text and code editors in Omarchy, specifically `zedconf/` for the Zed editor and `microconf/` for the Micro terminal editor.

## Architecture and Structure
Editor configurations are organized under dedicated modular directories in the repository root:
- `zedconf/`:
  - `data/settings.json`: Base configuration (editor appearance, tab sizes, formatting, language servers).
  - `data/linux/settings.json`: Linux-specific font and keymap overrides.
  - `data/keybindings.json`: Universal keybinding customizations.
  - `data/snippets/`: Custom code snippets per language.
  - `install.sh`: Idempotent installer script that merges configurations into `~/.config/zed/` with automatic backups.
- `microconf/`:
  - `data/settings.json`: Micro editor defaults (`"colorscheme": "omarchy"`, `softwrap`, `autoindent`, `diffgutter`, `tabsize 4`, `tabstospaces true`, `mouse true`).
  - `data/bindings.json`: Micro keybindings (Ctrl-s, Ctrl-q, Ctrl-z, Ctrl-y, Ctrl-f, Ctrl-c, Ctrl-v, splits).
  - `install.sh`: Idempotent installer that merges settings into `~/.config/micro/`, preserves user backups, and triggers the `micro-theme` hook.

## Operational Workflow
- Installing Zed configuration: `make zed` or `bash zedconf/install.sh`
- Installing Micro configuration: `make micro` or `bash microconf/install.sh`
- Installing both configurations: `make editors`
- Real-time Theme Synchronization: `make theme` or `bash hooks/theme-set.d/micro-theme`

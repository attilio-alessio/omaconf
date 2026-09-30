---
name: omarchy-theming
description: >-
  Procedures for managing Omarchy desktop theme hooks, Yaru folder color customization, and icon theme propagation.
---

# Omarchy Theming

## Overview
This skill describes the architecture and execution of desktop theme hooks that automatically synchronize Omarchy system themes with matching Yaru folder colors.

## Theme Hook Workflow
The core theme hook implementation resides in `hooks/theme-set.d/folder-color` within the repository. The hook is deployed to user configurations by copying it into `~/.config/omarchy/hooks/theme-set.d/folder-color` with executable permissions, allowing Omarchy theme switching events to trigger it automatically.

## Execution and Testing
Installing the user hook is executed via `make hook`. Testing or reapplying icon colors for the active desktop theme is executed via `make icons` or by executing `bash hooks/theme-set.d/folder-color` directly in user space.

## Theme Palette Mapping
The hook maps Omarchy desktop themes to specific Yaru icon palette variants. Themes `everforest` maps to `sage`, `gruvbox` maps to `yellow`, `nord` maps to `blue`, `tokyo-night` and `dracula` map to `purple`, `catppuccin` maps to `magenta`, `rose-pine` maps to `pink`, `solarized-dark` and `solarized-light` map to `cyan`, and `default` or unrecognized themes fallback to `orange`.

## GSettings Propagation
Icon theme changes are applied directly to the GNOME desktop interface schema by invoking `gsettings set org.gnome.desktop.interface icon-theme "Yaru-<color>"` within the active user session.

## Micro Editor Theme Synchronization
Micro editor colorscheme generation and synchronization is managed by `hooks/theme-set.d/micro-theme`. The hook reads active palette definitions from `/usr/share/omarchy/themes/<theme>/colors.toml`, generates custom `.micro` colorscheme files inside `~/.config/micro/colorschemes/omarchy.micro` (and `omarchy-<theme>.micro`), and updates `~/.config/micro/settings.json` with `"colorscheme": "omarchy"` seamlessly upon theme switching.

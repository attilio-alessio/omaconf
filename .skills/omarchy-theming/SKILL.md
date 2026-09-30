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
The hook resolves the active theme name from the Omarchy state directory, normalizes it to lowercase with spaces turned into hyphens, and selects an icon palette variant for it. The mapping lives in a single case statement inside the hook and is the only home for it, so a new theme needs exactly one new entry there. Every entry resolves to one of the palette variants the icon theme actually ships, and the case always ends in a default arm, so an unknown or newly released theme still gets a sensible folder color instead of no icons at all. Keep the default arm valid when you add entries, and prefer reusing an existing variant over introducing one the icon theme does not provide.

## GSettings Propagation
Icon theme changes are applied directly to the GNOME desktop interface schema by invoking `gsettings set org.gnome.desktop.interface icon-theme "Yaru-<color>"` within the active user session.

## Micro Editor Theme Synchronization
Micro editor colorscheme generation and synchronization is managed by `hooks/theme-set.d/micro-theme`. The hook reads active palette definitions from `/usr/share/omarchy/themes/<theme>/colors.toml`, generates custom `.micro` colorscheme files inside `~/.config/micro/colorschemes/omarchy.micro` (and `omarchy-<theme>.micro`), and updates `~/.config/micro/settings.json` with `"colorscheme": "omarchy"` seamlessly upon theme switching.

## Preview Uniformity
Desktop theme changes are not the only thing that has to stay consistent. Previews are the exception, and `scripts/lib/theme-preview.sh` enforces the uniform geometry, colour model, depth and density that the picker relies on. The theme stage applies it during setup and the update hook re-applies it after a package refresh, so a new theme shipped upstream is normalized without anyone editing a preview by hand.

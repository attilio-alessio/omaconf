---
name: system-debloat-cleanup
description: >-
  Procedures for removing default Omarchy web application shortcuts, package cleanup, and pacman configuration pinning.
---

# System Debloat Cleanup

## Overview
This skill outlines how to remove default web application launchers, uninstall unwanted packages, and prevent their automatic reinstallation on Arch Linux Omarchy installations.

## Desktop Launcher Cleanup
Web application desktop shortcuts installed under `/usr/share/omarchy/applications` and user desktop menus are cleaned by removing launcher definitions for Basecamp, Google Contacts, Google Maps, Google Messages, Google Photos, Discord, HEY, WhatsApp, X, YouTube, and Zoom.

## Package Removal and Replacement
Unneeded software packages including Chromium, the GNOME desktop stack (Nautilus, Totem, Evince, Eog, Yaru icon theme), the KDE stack (Dolphin, Okular, Gwenview, xdg-desktop-portal-kde, plasma-integration, breeze, breeze-gtk, Haruna), system-config-printer, Kdenlive, OBS Studio, LibreOffice, and Obsidian are cleanly removed from the package database. The provisioned stack is CLI/TUI only with Brave Origin as browser, Micro, Yazi, imv, mpv, Zathura, Neovim, omarchy-nvim, Herdr, and Gum. The container runtime is podman; docker is never provisioned.

## Pacman Persistence
To ensure removed packages are not pulled back into the system during subsequent system upgrades, package names are listed inside `/etc/pacman.d/omablot/ignore-pkgs.list` and pinned directly into `/etc/pacman.conf` within the `IgnorePkg` directive.

---
name: omamp-development
description: >-
  Expert guide and procedures for developing, maintaining, and testing the omamp
  media player plugin for the Omarchy desktop shell and Quickshell environment.
  Use when modifying, debugging, or enhancing omamp or other Omarchy bar widgets.
---

# omamp Development & Maintenance Skill

This skill documents the design patterns, MPRIS integration rules, and reload workflows for the `omamp` media player plugin in Omarchy shell.

## 1. Quick Workflow & Commands

- **Local Plugin Link**:
  `~/.config/omarchy/plugins/krosci.omamp -> /home/kairosci/Projects/omamp`
- **Apply / Reload Shell**:
  Always reload the Omarchy desktop shell after making changes:
  ```bash
  omarchy restart shell
  ```
- **Git Push**:
  Target repository: `https://github.com/krosci/omamp` on branch `master`.

## 2. Core Conventions & Design Principles

### Bar Widget Visibility & Collapsing
- The bar widget **MUST collapse completely** when idle (no active media/tracks):
  ```qml
  visible: root.hasMedia
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0
  ```
- **Distinction between Paused and Idle**:
  - **Playing**: `isPlaying = true`, `hasMedia = true` -> Visible (icon `󰏤`).
  - **Paused**: `isPlaying = false`, `hasMedia = true` (valid `trackTitle` / `trackArtist`) -> Visible (icon `󰐊`).
  - **Idle / No track**: `hasMedia = false` -> Hidden completely (`implicitWidth = 0`).

### Text Cleaning & Parentheses Trimming
- Song titles frequently contain noise like `(feat. ...)`, `(ft. ...)`, `[2024 Remaster]`, `(Official Audio)`.
- Always process titles through `MediaModel.cleanTitle(title)` which strips `(...)` and `[...]` while preserving clean strings.

### Typography & Motion Guidelines
- **No marquee or back-and-forth text animations**: Title text must be static and cleanly truncated using `elide: Text.ElideRight` and `renderType: Text.NativeRendering`.
- Match Omarchy design standards (flat buttons, `radius: 0`, standard `Style` spacing and font metrics).

## 3. Project Architecture

- **`manifest.json`**: Plugin metadata and entry point (`src/BarWidget.qml`).
- **`src/BarWidget.qml`**: Bar icon widget, player lifecycle listeners, volume control, track queue/history, and popup trigger.
- **`src/MediaModel.js`**: Pure JS helper library for active player selection, title cleaning, timestamp formatting, and track queue management.
- **`src/MediaPopup.qml`**: Full player popup panel, track metadata display, volume controls, queue/recents view, and multi-source switcher.
- **`src/TimeSlider.qml`**: Interactive track seek bar with elapsed and total duration labels.
- **`src/VolumeSlider.qml`**: Interactive volume slider with dynamic level icons and mute/unmute toggle.
- **`src/AlbumArt.qml`**: Hardware-accelerated masked artwork renderer with fallback glyph.

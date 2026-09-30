---
name: omamp-development
description: >-
  Expert guide and procedures for developing, maintaining, and testing the omamp
  media player plugin for the Omarchy desktop shell and Quickshell environment.
  Use when modifying, debugging, or enhancing omamp or other Omarchy bar widgets.
---

# omamp Development and Maintenance

This skill documents the design patterns, the MPRIS integration rules and the reload workflow for the `omamp` media player plugin in the Omarchy shell.

## Local Workflow

The plugin is installed from this repository through the project plugin catalog, which declares the identifier, the upstream source and the bar section it belongs to. During development it is convenient to link the checkout into the user plugin directory instead of reinstalling, pointing the plugin entry at the local path. The identifier must stay identical to the one declared in the catalog entry, because the desktop shell keys its installed plugins by that string.

After any code change, reload the Omarchy desktop shell so the widget is rebuilt from the new sources. Pushing goes to the plugin upstream declared in the catalog, on its default branch.

## Design Principles

The bar widget must collapse completely when idle, which means driving the visible property and all three implicit dimensions from the same media flag. A widget whose visibility goes false but whose implicit width stays constant still occupies space in the bar and leaves a dead gap, so treat the flag as the single source of truth for geometry.

Paused and idle must stay distinct. Playing means the media flag and the playing flag are both set, and the widget shows the pause affordance. Paused means media is loaded and the track metadata is valid but playback is not advancing, so the widget stays visible and shows the play affordance, keeping the resume control and the panel trigger reachable. Idle means no media is loaded at all, so the widget collapses. Only metadata, not playback progress, decides visibility.

## Text Cleaning

Song titles routinely contain noise such as featured artist credits, release tags and official audio markers. Always pass a title through the model helper that strips parenthetical and bracketed fragments while preserving an already clean string, and never bind the raw session title to a label. Escaping or formatting belongs in the model helper so every component benefits from the same result.

## Typography and Motion

Title text must be static and cleanly truncated using a right elide mode and native text rendering. Do not add marquee or back and forth animations to a bar widget. Match the shell design standards, keeping flat buttons, square corners and the standard spacing and font metrics so the widget does not stand out from its neighbours.

## Project Architecture

The plugin manifest carries the metadata, the entry point and the bar section configuration, including whether more than one instance may exist. The bar widget holds the icon, the player lifecycle listeners, the volume control, the track history and the popup trigger. The popup component holds the full player panel with album art, track metadata, progress, volume, the queue and recent view and the multi source switcher. The shared model is a plain helper that owns active player selection, title cleaning, timestamp formatting and the track queue. The album art component renders masked artwork with a fallback glyph so a missing cover never leaves a hole in the panel.

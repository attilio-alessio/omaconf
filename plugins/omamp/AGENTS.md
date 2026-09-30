# omamp Development Guidelines

## Overview
This document records the rules that govern changes to the `omamp` media player plugin. The plugin is a Quickshell bar widget registered through the project plugin catalog, and its visual state is driven entirely by the media session, so most defects come from an incorrect state mapping rather than from a layout mistake.

## Title Formatting
Song titles carry a lot of noise, most often parenthetical and bracketed fragments such as featured artist credits, remaster markers and official audio tags. Always normalize a title through the model helper that strips those fragments while leaving a clean string untouched, and never let the raw session title reach the label. Keep the displayed text static and truncate it with a right elide mode, without a marquee or any oscillating animation, because a bar widget that reflows itself is distracting at a glance.

## Bar Widget Lifecycle and Visibility
The widget must collapse completely when there is no media loaded, which means driving both the visibility and the implicit geometry from the same media flag rather than only hiding the icon. When a track is playing the widget stays visible and shows the pause affordance. When a track is loaded but paused the widget also stays visible and shows the play affordance, because the user must be able to resume or reopen the panel. When the player is idle, stopped or reporting no usable metadata the widget collapses to zero width entirely.

Keeping paused and idle visually distinct is the part that gets broken most often. A paused player still has a title and an artist, so it belongs to the visible state, and collapsing it would hide the resume control.

## Applying Changes
After any code change, reload the Omarchy desktop shell so the widget picks up the new sources instead of testing stale state.

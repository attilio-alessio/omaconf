# theme previews

Regenerated Omarchy theme previews with yazi as file manager in place of stock manager while keeping all other apps from the original shot.

## Index

This guide covers purpose and layout and apply flow and verification.

## Purpose

Upstream previews show the stock file manager. This folder stores rebuilt previews for twenty two Omarchy themes. The capture script refreshes Last Horizon and Lupine by default, using an isolated fullscreen Kitty window with the `termfilemanager` class and Yazi in a free workspace. It uses `/tmp/homeshot` as a temporary home directory and opens Yazi at its root. The capture is scaled proportionally and centered in the lower-right tile, aligned with the lower-left pane and kept clear of the upper-right system monitor. Lupine's old file chooser area is covered with its theme background. The script refuses to run if `/tmp/homeshot` already exists and removes that directory after a successful or interrupted capture.

## Layout

The folder holds rebuilt images under theme folders matching theme names plus the capture and apply helpers in this folder. Pass theme slugs to rebuild other previews.

```bash
ls theme-previews/gruvbox/preview.png
ls theme-previews/nord/preview.png
bash theme-previews/rebuild-previews.sh
bash theme-previews/rebuild-previews.sh nord gruvbox
bash theme-previews/apply.sh nord gruvbox
```

## Apply flow

The helper creates per-user overlay folders as needed, keeps a guarded backup of an existing preview, installs rebuilt files with user-only permissions, and clears the picker cache so the carousel rebuilds on next launch. It does not change package-owned files under `/usr/share/omarchy/`.

```bash
bash theme-previews/apply.sh
ls ~/.config/omarchy/themes/gruvbox/preview.png
```

## Verification

Open the theme picker and confirm the Last Horizon and Lupine cards show Yazi's themed wallpaper preview across the previous file-chooser region with no Nautilus content behind it.

```bash
identify theme-previews/gruvbox/preview.png
md5sum theme-previews/gruvbox/preview.png
```

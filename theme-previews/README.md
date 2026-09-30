# Theme Previews

Each generated preview shows Neovim and btop side by side, using the selected Omarchy theme. This replaces the old Yazi overlay composition with a real capture of the themed desktop, where the editor and system monitor are the two main panes.

## Rebuild

Pass the theme slugs explicitly. The capture opens both applications on an isolated Hyprland workspace, uses the installed Neovim and btop theme configuration, and captures the focused monitor at its actual pixel scale. The script restores the original theme and workspace on exit and applies generated previews to the current user's Omarchy theme overlays.

```bash
bash theme-previews/rebuild-previews.sh <theme> [<theme> ...]
```

## Apply Flow

The helper creates per-user overlay folders, keeps a guarded backup of any preview it replaces, and clears the picker cache. Without the privileged flag it never touches package-owned files.

```bash
bash theme-previews/apply.sh <theme>
```

System scope requires root and explicit theme names. It records the generated image in the durable overlay store so the post-update hook restores it after package updates.

```bash
pkexec env PKEXEC_UID="$(id -u)" bash theme-previews/apply.sh --system <theme> [<theme> ...]
```

## Image Contract

`scripts/lib/theme-preview.sh` owns the shared normalization contract: 1800x1012 pixels, alpha-capable PNG, 8-bit depth and 72 DPI. The output uses PNG32, and the same library keeps stock backups and restores system overlays after updates.

## Verification

Inspect previews from both light and dark themes. Each image should show Neovim on the left and btop on the right, with readable text and matching theme colors. Confirm all images meet the shared geometry, color, depth and density contract.

# Theme Previews

Omarchy theme previews regenerated with Yazi as the file manager in place of the stock one, while every other application in the shot is left as it was.

## Purpose

Upstream previews show the stock file manager, which is not what the desktop actually uses. The purpose of this folder is to produce previews that show Yazi, for whichever themes you choose, and to keep the resulting artwork uniform enough that the theme picker lays every card out identically.

The capture is opt-in and refuses to run without explicit theme slugs, so no theme can silently drift apart. It runs an isolated fullscreen Kitty window with the file manager class, opens Yazi on a free workspace against a temporary home directory, and cleans that directory up whether the capture succeeds or is interrupted. The capture is scaled proportionally and centered in the lower-right tile, aligned with the lower-left pane and kept clear of the upper-right system monitor, and any gap left by the proportional fit is filled with the theme background.

Themes whose upstream artwork ships at a different resolution are normalized before compositing, so they land on the same layout as the rest.

## Usage

The folder holds one image per theme folder plus the capture and apply helpers. Always pass explicit theme slugs; without arguments the capture script exits with a usage error and changes nothing.

```bash
bash theme-previews/rebuild-previews.sh <theme> [<theme> ...]
bash theme-previews/apply.sh <theme> [<theme> ...]
```

## Apply Flow

The helper creates the per-user overlay folders as needed, keeps a guarded backup of any preview it is about to replace, installs the rebuilt files with user-only permissions and clears the picker cache so the carousel rebuilds on the next launch. Without the privileged flag it never touches package-owned files.

```bash
bash theme-previews/apply.sh <theme>
```

The privileged mode widens the scope to the shared theme tree, so the artwork applies to every user and outside the current session. It requires root and it insists on explicit theme names, so stock artwork belonging to themes you did not choose is never pinned into the durable overlay store.

```bash
pkexec env PKEXEC_UID="$(id -u)" bash theme-previews/apply.sh --system <theme> [<theme> ...]
```

## Uniform Format

Every preview is normalized to the same contract: a fixed geometry, an alpha channel, a fixed bit depth and a fixed density. `scripts/lib/theme-preview.sh` owns that contract and exposes the single check every caller uses, which is what makes the guarantee hold across the setup stage, the update hook and the apply helper.

Normalization exists because upstream is inconsistent. Some themes omit the alpha channel and some ship at a different resolution, so without a single enforced contract the cards disagree on grid, colour model and density, and a scaled tile lands in the wrong place.

Previews that already satisfy the contract are skipped, which keeps the library idempotent. An original that still needs resizing is written once to the stock cache directory so the untouched asset can always be restored. Because the shared theme tree is package-owned, writing into it makes the package manager report those files as altered, which is expected.

## Scaled File Manager Tile

The tile is stored as a reference offset and a reference size against a reference canvas, and it is resolved against the real canvas of the normalized preview on every rebuild. No pixel value is hardcoded, so the capture stays registered to the file manager window even if the canvas changes. The composite is written through an explicit PNG32 coder so it always carries the alpha channel the stock artwork has.

## Durability

A system-scope apply records each composite in the overlay store under `/var/lib`. The post-update hook reinstalls a stored overlay whenever the package copy drifts, so the artwork survives a full system upgrade instead of reverting to the stock file manager. Only the explicitly applied themes are recorded, which leaves the remaining stock previews free to follow upstream updates.

## Verification

Open the theme picker and confirm that the rebuilt cards show Yazi with no trace of the stock file manager, while untouched cards keep the stock artwork. Confirm that the rebuild script without arguments prints the usage line and leaves the preview tree untouched. Confirm that every preview reports the same geometry, colour model, depth and density.
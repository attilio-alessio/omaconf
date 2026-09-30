# Omablot – Default attuali e Sprint di perfezionamento

## 1. Default attuali (snapshot strutturale)

Stage `20-defaults.sh` + `30-theming.sh` + `10-debloat.sh`:

- Browser: `brave-origin` (`omarchy default browser brave-origin`, `brave-origin-bin` da AUR verificato)
- Editor: `micro` (`~/.local/state/omarchy/defaults/editor`, `microconf/install.sh`)
- File manager: `yazi` (`xdg-mime` + `gio mime` + `mimeapps.list` → `yazi.desktop`, stato `defaults/file-manager`, shortcut Hypr `SUPER+SHIFT+F` → `xdg-terminal-exec yazi`)
- PDF: `zathura` (+ `zathura-pdf-mupdf`, `org.pwmt.zathura.desktop`)
- Immagini: `imv` (pulizia scorie `gwenview` → `imv`)
- Media: `mpv` (stato `defaults/media-player`)
- Icone: `Yaru-dark` e varianti per tema via `gsettings`, hook `folder-color` + `micro-theme`
- Debloat: `kdenlive obs-studio obsidian libreoffice-fresh chromium neovim omarchy-nvim`, pin `IgnorePkg` in merge (mai overwrite), manifest `omarchy-base.packages` ripulito, webapp rimosse
- Persistenza: hook `pre-refresh-pacman.d/99-omablot-persist` (re-merge `IgnorePkg` dopo l'overwrite di `omarchy-refresh-pacman`) e `post-update.d/99-omablot-persist` (re-merge + re-debloat + re-defaults MIME) installati per ogni utente in `~/.config/omarchy/hooks/`
- Plugin index: `plugins/index.json`, submodule `plugins/omamp` (sorgente `https://github.com/krosci/omamp.git`)

## 2. Sprint applicati

- Sprint 1 – default strutturali: enforcement MIME a tre livelli (`xdg-mime`, `gio`, `mimeapps.list`), canonicalizzazione scorie Nautilus/Evince/Gwenview, stato `defaults/file-manager`, override Hypr idempotente con marker `omablot-yazi-fm`
- Sprint 2 – persistenza debloat: `IgnorePkg` in merge (preserva pin omaqt/terzi), hook pre-refresh e post-update self-contained e idempotenti
- Sprint 3 – prompt strutturato e strutturale (sezione 3): workflow obbligatorio per ogni modifica futura
- Sprint 4 – submoduli e repo index: push modifiche `omamp`, submodule `plugins/omamp`, `plugins/index.json`

## 3. Prompt strutturato e strutturale

Ogni intervento su omablot deve seguire questo prompt:

1. Diagnosi: leggere moduli, test, `mimeapps.list`, binding Hypr e dispatcher `omarchy` prima di toccare codice
2. Causa radice: distinguere default XDG, override Omarchy e reinstall da update (`omarchy-refresh-pacman` sovrascrive `/etc/pacman.conf`)
3. Modifica minima e idempotente: `set -euo pipefail`, mai `|| true` (usare `|| warn`), mai path utente hardcoded (solo `/home/*` o `$HOME`), niente `systemd-run`, niente commenti in `Makefile` e hook
4. Tre livelli di default: ogni default applicativo va fissato a livello XDG (`xdg-mime`), Gio (`gio mime`) e file (`mimeapps.list`), più stato Omarchy e shortcut
5. Persistenza agli update: ogni pin/debloat deve sopravvivere a `omarchy-refresh-pacman` (merge, mai overwrite) e a `omarchy update` (hook `pre-refresh-pacman.d` + `post-update.d`)
6. Verifica: `bash tests/run-all.sh` e `bash scripts/verify.sh` prima di ogni commit; aggiornare i test quando cambia il comportamento atteso
7. Commit: Conventional Commits `<type>: <descrizione>` senza emoji né punteggiatura extra, poi push su `main` e sui submoduli toccati

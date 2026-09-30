# clean

Safe system and home cleanup after debloat for Omarchy on Arch Linux. Hygiene only, never package installs or removals beyond orphans and cache.

## Index

This guide covers purpose and boundaries and central setup and system module and home module and central verification and interactive launch and logs and tests and suite.

## Purpose and boundaries

This repo removes leftovers left by debloat when app and binary both result absent. It never touches vaults, documents, installed apps, editor configs. It operates per real user under existing homes, with presence guards before each deletion.

## Central setup

Real file for setup runs as root, opens log in append, sets strict mask, resolves message functions and calls the two modules in order.

Usage code without comments:

```bash
sudo bash scripts/setup.sh
bash scripts/run-setup.sh
bash scripts/launch.sh
make setup
```

## System module

Real file for system module holds real actions in order with cache trim to last two versions when dedicated command exists else cache clean of uninstalled and orphan removal through dedicated query and journal vacuum to size and time limit and coredump prune older than fourteen days and top level tmp clean older than seven days and var tmp older than fourteen days and unused flatpak runtime removal only when command exists and font cache regen.

Inspection code without comments:

```bash
paccache -rk2 --noconfirm
pacman -Sc --noconfirm
pacman -Qtdq
journalctl --vacuum-size=200M --vacuum-time=2weeks
find /var/lib/systemd/coredump -mindepth 1 -mtime +14 -delete
find /tmp -mindepth 1 -maxdepth 1 -atime +7 -exec rm -rf {} +
find /var/tmp -mindepth 1 -maxdepth 1 -atime +14 -exec rm -rf {} +
flatpak uninstall --unused -y
fc-cache -f
```

Idempotence holds each step on empty set ending with zero changes and each command degraded to warn never breaking chain.

## Home module

Real file for home module holds per home conditional cleanup. When package results installed or binary present, it skips all for that app. Otherwise it removes config and cache and data paths listed for that app. Then it sweeps obsolete launchers and residual Omarchy webapps and thumbnails older than thirty days and trash older than thirty days.

Covered apps hold kdenlive with dedicated config and cache and obs studio with dedicated config and obsidian with dedicated config and never vaults and libreoffice with config and cache and chromium with config and cache and system printers with dedicated config and nautilus and totem and evince and eog for GNOME stack and dolphin and okular and gwenview and haruna for KDE stack and kitty terminal configuration.

Inspection code without comments:

```bash
ls /home
pacman -Q chromium
command -v chromium
ls ~/.config/chromium
ls ~/.cache/chromium
ls ~/.local/share/applications
find ~/.cache/thumbnails -mindepth 1 -atime +30 -delete
find ~/.local/share/Trash/files -mindepth 1 -atime +30 -delete
```

Idempotence holds second run finding paths already absent and ending with zero changes.

## Central verification

Real file for verify only reads, never writes. It checks absent orphans and journal under threshold and absent recent coredumps and absent home leftovers for removed apps and absent residual webapps and absent old thumbnails and trash and absent manual installs from external sources.

Verification code without comments:

```bash
bash scripts/verify.sh
make verify
pacman -Qtdq
journalctl --disk-usage
```

## Interactive launch and logs

Real file for non interactive launch holds log path print and setup delegation. Real file for interactive launch holds final pause for output reading.

Usage code without comments:

```bash
bash scripts/run-setup.sh
bash scripts/launch.sh
```

## Tests and suite

Real suite in `tests` with single run file covers system cleanup and home cleanup and syntax and modular pipeline and idempotence safety. Each test uses asserts on real strings and observed behavior.

Test code without comments:

```bash
bash tests/run-all.sh
make test
bash tests/test_system_cleanup.sh
bash tests/test_home_cleanup.sh
```

Operating rules in `AGENTS.md` and runbook in `.skills/system-cleanup`. Family contract in profile repo `omablot/.github` inside `docs`.

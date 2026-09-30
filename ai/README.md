# ai

Opt in AI debloat for Omarchy on Arch Linux. Nothing here runs alone. Terminal only, never separate windows.

## Index

This guide covers purpose and boundaries and central entry and single AI module and verification and tests and shared rules.

## Purpose and boundaries

This repo removes AI noise while leaving real tools intact. On explicit request it disables assisted crash reports, turns off agents plugin, deletes standalone launchers. It never touches mise managed CLI, never touches tensaku which is a screenshot annotator, never touches editors, shell or themes. TUI matches CLI and stays default inherited from terminal. Policy holds that AI tools run inside the terminal.

Real repo structure:

```bash
bash scripts/debloat-ai.sh
sudo bash scripts/debloat-ai.sh --yes
make debloat-ai
bash tests/check.sh
```

## Central entry

Real file for entry shows plan with zero option and exits. With request option it requires elevated privileges, exports explicit flag and calls the single module. It also defines per user Omarchy command launch with correct desktop environment.

Usage code without comments:

```bash
bash scripts/debloat-ai.sh
sudo bash scripts/debloat-ai.sh --yes
make debloat-ai
```

Observed behavior holds plan print and close with zero status with zero option and root check and internal flag set with option and single module sourcing with shared log functions and per user runtime and bus resolve from user id.

## Single AI module

Real file for module runs only when called from entry with active internal flag, otherwise it prints invite and exits with zero effects. Real actions in order hold per home disable and mask of crash watch unit in user scope and per home disable of agents plugin through per user Omarchy command and per home removal of desktop launchers with targeted globs in local path and system path removal with same globs.

Inspection code without comments:

```bash
printf '%s\n' "$OMABLOT_AI_DEBLOAT"
ls /home
systemctl --user status omarchy-crash-watch.service
omarchy plugin list
ls ~/.local/share/applications
ls /usr/share/applications
```

Real globs handled by module:

```bash
ls ~/.local/share/applications/*opencode*.desktop
ls ~/.local/share/applications/*copilot*.desktop
ls ~/.local/share/applications/*agy*.desktop
ls ~/.local/share/applications/*claude*.desktop
ls ~/.local/share/applications/*codex*.desktop
ls ~/.local/share/applications/*gemini*.desktop
ls ~/.local/share/applications/*aider*.desktop
ls ~/.local/share/applications/*ollama*.desktop
```

Idempotence holds repeated disable and mask as null operations and removal of absent files as null with presence guard.

## Verification and tests

Real test file is valid alone with zero external libs. It checks internal flag and mise and tensaku names and crash unit and agents plugin and launcher list and Bash syntax of both scripts and no option execution with explicit request phrase in shown text.

Verification code without comments:

```bash
bash tests/check.sh
bash -n scripts/debloat-ai.sh
bash -n scripts/modules/40-ai.sh
```

## Shared rules

Native Bash automation with rigid mode, foreground, warns for non critical steps, paths from real homes, strict idempotence. Details in `AGENTS.md`. Family contract in profile repo `omablot/.github` inside `docs`.

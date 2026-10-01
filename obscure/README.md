# obscure

Gaze protection for Omarchy on Arch Linux. Yazi previews locked under password plus native idle lock.

## Index

This guide covers purpose and boundaries and central setup and yazi module and idle module and opener binary and pattern data and plugin and central verification and launch and logs and tests and suite.

## Purpose and boundaries

This repo hides sensitive content in preview pane and requires login password for opening. It never touches documents, vaults or installed apps beyond preview and open gate. For idle it ships zero custom lockers, it only removes flags that inhibit native chain.

## Central setup

Real file for setup runs with elevated privileges through graphic manager, opens log in append, calls the two modules in order.

Usage code without comments:

```bash
pkexec bash scripts/setup.sh
bash scripts/run-setup.sh
bash scripts/launch.sh
make setup
```

## Yazi module

Real file for yazi module holds reading sensitive globs from pattern data excluding empty lines and comments and building preview and icon and open rule and opener blocks and installing opener binary in system path with executable perms and per home creation of plugin and config folders and lua plugin copy and pattern copy and base config creation when absent and block append with markers only when absent and ownership fix per user.

Inspection code without comments:

```bash
cat data/patterns
ls data/obscure.yazi
cat ~/.config/yazi/yazi.toml
cat ~/.config/yazi/theme.toml
cat ~/.config/obscure/patterns
ls ~/.config/yazi/plugins/obscure.yazi
ls /usr/local/bin/obscure-view
```

Managed blocks hold dedicated markers for preview with obscured run and red icons with zero text and rules with dedicated opener use and openers with blocking command for unix.

Idempotence holds appends guarded by marker check and plugin copy with remove and copy deterministic and ownership refixed each run.

## Idle module

Real file for idle module holds per home removal of stay awake indicator and screensaver off toggle. It leaves native defaults with blank after one hundred fifty seconds and lock after three hundred seconds. It ships zero custom lockers.

Inspection code without comments:

```bash
ls ~/.local/state/omarchy/indicators/stay-awake
ls ~/.local/state/omarchy/toggles/screensaver-off
```

Idempotence holds removal of absent files as null.

## Opener binary

Real file for opener installed in system path asks password through system manager with terminal fallback, verifies with privileged command fed by pipe and at once drops timestamp, rejects empty password, pages text in pager, views PDF documents via zathura or pdftotext or desktop opener, and opens other types with desktop open.

Usage code without comments:

```bash
obscure-view ~/sample.pdf
OBSCURE_PASSWORD=testword PAGER=cat obscure-view ~/note.txt
which obscure-view
```

## Pattern data and plugin

Real file for patterns holds nineteen globs including two factor secrets and backup codes and recovery keys and passkeys and passwords and secrets and credentials and seed phrases and mnemonics and pem and key and kdbx. Real file for lua plugin holds peek and seek functions that show only lock screen with zero delegation to code preview.

Inspection code without comments:

```bash
cat data/patterns
cat data/obscure.yazi/main.lua
cat ~/.config/obscure/patterns
```

## Central verification

Real file for verify checks helper presence and per user plugin and per user patterns and marked blocks in configs and absent idle flags.

Verification code without comments:

```bash
bash scripts/verify.sh
make verify
```

## Launch and logs

Real file for non interactive run and real file for interactive run with final pause.

Usage code without comments:

```bash
bash scripts/run-setup.sh
bash scripts/launch.sh
```

## Tests and suite

Real suite in `tests` with single run file covers yazi gate and password helpers with isolated home and idle and syntax and pipeline and idempotence.

Test code without comments:

```bash
bash tests/run-all.sh
make test
bash tests/test_yazi_gate.sh
bash tests/test_auth_helpers.sh
bash tests/test_idle.sh
```

Operating rules in `AGENTS.md` and runbook in `.skills/privacy-shield`. Family contract in profile repo `omaconf/.github` inside `docs`. Operating note holds that after yazi config reinstall from debloat repo this setup needs rerun.

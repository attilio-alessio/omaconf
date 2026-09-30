# performance

Prudent energy and runtime for Omarchy on Arch Linux. Fixed charge threshold, hibernate on low battery, conservative tuning.

## Index

This guide covers purpose and boundaries and central setup and energy module and runtime module and central verification and interactive launch and logs and tests and suite.

## Purpose and boundaries

This repo owns full energy policy. It states threshold once in dedicated file and enforces it on three cooperating layers. It never touches hardening, debloat, themes. Runtime tuning stays minimal to avoid desktop instability.

## Central setup

Real file for setup runs as root, opens log in append, sets strict mask, calls the two modules in order.

Usage code without comments:

```bash
sudo bash scripts/setup.sh
bash scripts/run-setup.sh
bash scripts/launch.sh
make setup
```

## Energy module

Real file for energy module holds real actions in order with policy folder creation and single source file with seventy five limit and udev rule to reapply limit on add or change of power supply for BAT and BATT names on three exposed attributes and udev reload and retrigger on power supplies and tmpfiles drop for early boot write on four paths and dedicated tmpfiles apply and oneshot service that reads policy and writes limit to each present node and wanted also by suspend and hibernate targets and daemon reload and service enable and start and at once limit write on writable nodes and UPower drop with twenty and ten and five thresholds and hibernate action on action threshold and energy service restart with warn degradation.

Inspection code without comments:

```bash
cat /etc/omaconf/power.conf
cat /etc/udev/rules.d/98-battery-charge-threshold.rules
cat /etc/tmpfiles.d/battery-charge-threshold.conf
cat /etc/systemd/system/battery-charge-threshold.service
systemctl is-enabled battery-charge-threshold.service
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
cat /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf
systemctl status upower.service
```

Real generated files:

```bash
ls /etc/omaconf/power.conf
ls /etc/udev/rules.d/98-battery-charge-threshold.rules
ls /etc/tmpfiles.d/battery-charge-threshold.conf
ls /etc/systemd/system/battery-charge-threshold.service
ls /etc/UPower/UPower.conf.d/99-omaconf-low-battery.conf
```

Idempotence holds full deterministic overwrite and repeated enables as null and same value write as null.

## Runtime module

Real file for runtime module holds periodic trim timer enable for SSD and sysctl drop with disabled NMI watchdog and full set apply and energy profiles daemon enable only when package exists.

Inspection code without comments:

```bash
systemctl is-enabled fstrim.timer
cat /etc/sysctl.d/99-perf.conf
cat /proc/sys/kernel/nmi_watchdog
pacman -Q power-profiles-daemon
systemctl is-enabled power-profiles-daemon.service
```

Idempotence holds repeated enables as null and identical file write as null.

## Central verification

Real file for verify only reads. It checks policy with expected value and presence of five artifacts and enabled service and live value on existing nodes and UPower drop with four thresholds and action and sysctl drop with disabled watchdog and enabled trim timer.

Verification code without comments:

```bash
bash scripts/verify.sh
make verify
```

## Interactive launch and logs

Real file for non interactive run and real file for interactive run with final pause.

Usage code without comments:

```bash
bash scripts/run-setup.sh
bash scripts/launch.sh
```

## Tests and suite

Real suite in `tests` with single run file covers energy policy and runtime tuning and syntax and pipeline and idempotence.

Test code without comments:

```bash
bash tests/run-all.sh
make test
bash tests/test_power_policy.sh
bash tests/test_performance_tuning.sh
```

Operating rules in `AGENTS.md` and runbook in `.skills/power-performance`. Family contract in profile repo `omaconf/.github` inside `docs`.

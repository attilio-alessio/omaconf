---
name: power-performance
description: >-
  Procedures for managing battery charge threshold policy, low-battery hibernate protection, and safe runtime performance tuning on Omarchy.
---

# Power Performance

## Overview

This skill defines how the performance microcomponent protects battery longevity and session survival while applying a small set of runtime tunings that can never destabilize the desktop. The single source of truth for the charge limit is `/etc/omaconf/power.conf`. Every other artifact is generated from it by `scripts/setup.sh`, so the policy survives reboots, kernel updates, hotplug events, and suspend and resume cycles without manual intervention.

## Battery Threshold Management

The provisioning stage declares the 75 percent limit once and enforces it through three cooperating layers. The udev rule reapplies the limit whenever a power supply device appears or changes, which covers hotplug and resume. The systemd-tmpfiles drop-in writes the limit early at boot. The oneshot systemd service reads the policy file at runtime and writes the limit to every battery node the hardware exposes, and it is wanted by the suspend and hibernate targets so the policy cannot be silently dropped across sleep. Targeting uses the universal `BAT` and `BATT` kernel patterns so future batteries are covered automatically. Verification reads the live sysfs nodes and compares them against the declared policy.

## Low-Battery Session Protection

A charge threshold cannot stop discharge, so session survival is handled through hibernate. The UPower drop-in warns the user at 20 percent, escalates at the 10 percent critical level, and hibernates at 5 percent. Hibernate is required rather than suspend because suspend to RAM keeps draining the battery while hibernate draws nothing and preserves the full session to disk. Before changing any level, confirm that hibernate is available on the machine, since the action depends on configured swap and resume parameters.

## Runtime Tuning Standards

Runtime tuning stays conservative by design. Periodic SSD trim is enabled through the vendor timer unit rather than custom scheduling. The NMI watchdog is disabled through a dedicated sysctl drop-in that never touches the security microcomponent files. The power profiles daemon is enabled only when the package is present, and enabling never selects a profile, so desktop behavior is unchanged. Every tuning is asserted twice, once against the persisted file and once against live kernel or service state.

## Agent Workflow

Agents working in this repository diagnose first by reading the stage modules together with the verification script and the test suite. Changes stay minimal and idempotent under strict shell flags with graceful warnings for non-critical steps. Numeric policy values remain literal inside generated configuration files while the policy file stays canonical. Every change is validated with the full test suite and the verification script before any commit, and commits follow the Conventional Commits format defined in `AGENTS.md`.

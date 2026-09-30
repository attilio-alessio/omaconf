# Agent Guidelines and Codebase Knowledge

## Project Overview

performance is the energy and runtime microcomponent for Omarchy on Arch Linux. It owns low-battery hibernate and prudent runtime tuning. It consumes the canonical charge threshold module from the repository root and never defines a second battery policy. It never touches hardening or debloat or themes.

## Repository Architecture

Provisioning pipeline in scripts setup runs as root and delegates to two stage modules under scripts modules folder. Verification runner in scripts verify asserts persisted policy and live runtime state. Modular test suite under tests folder validates power policy and tuning and syntax and pipeline and safety through single run file. Logging is managed by run setup file and interactive execution is supported by launch file. Root Makefile exposes setup and verification and testing and cleanup targets. Operational runbook resides in skills folder with truly specific runbook only and shared runbooks living in profile repo.

## Ownership Details

Energy stage holds single source policy file with seventy five limit and udev rule and tmpfiles drop and oneshot service wanted by suspend and hibernate and at once write and UPower drop with twenty and ten and five thresholds and hibernate action. Runtime stage holds trim timer enable and sysctl drop with disabled NMI watchdog and profiles daemon enable when present.

## Boundaries and Safety

Threshold service is oneshot with zero background processes. Every privileged step degrades to warn. Sysctl drop uses own filename with never overwrite of hardening files. All changes validate with tests run file and scripts verify file.

## Commit Conventions

All commit messages follow Conventional Commits style with type and short description and colon as only punctuation after type. Titles hold never emoji and never exclamation and never extra punctuation.

## Scripting Rules and Structural Prompt

Scripts use rigid mode in pure native Bash with zero Python deps. Failures never suppress with blind true. Non critical steps use warn function for graceful degrade. User paths never hardcode and derive from home variable or home star paths. All operations run in foreground with zero background runner. All modifications to setup and verify remain strictly idempotent. Persisted numeric policy stays literal in generated files while policy file remains single source read at runtime. Single source holds for each rule with never scattered copies. Shared modules serve several places. Zero placeholders and zero fallbacks and zero temporary solutions and zero regressions and zero hand written values. Specific file names and touched paths and launched commands and expected results in each change. Full contract lives in profile repo inside docs folder with structured prompt and shared contract and critical review.

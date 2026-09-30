# Agent Guidelines and Codebase Knowledge

## Project Overview

clean is the post debloat hygiene microcomponent for Omarchy on Arch Linux. It owns safe system and home cleanup with zero package installs beyond orphans and cache and zero touches to vaults and documents and installed apps.

## Repository Architecture

Provisioning pipeline in scripts setup runs as root and delegates to two stage modules under scripts modules folder. Verification runner in scripts verify asserts hygiene and absent leftovers. Modular test suite under tests folder validates system cleanup and home cleanup and syntax and pipeline and safety through single run file. Logging is managed by run setup file and interactive execution is supported by launch file. Root Makefile exposes setup and verification and testing and cleanup targets. Operational runbook resides in skills folder with truly specific runbook only and shared runbooks living in profile repo.

## Ownership Details

System stage holds cache trim and orphan removal and journal vacuum and coredump prune and tmp clean and flatpak unused removal and font cache regen. Home stage holds per app leftover removal only when package and binary both absent and stale launcher sweep and webapp sweep and thumbnail prune and trash prune with thirty day thresholds.

## Boundaries and Safety

This repo never installs and never pins and never touches hardening or energy or themes. Home iteration derives from home star with presence guards and zero hard coded names. All changes validate with tests run file and scripts verify file.

## Commit Conventions

All commit messages follow Conventional Commits style with type and short description and colon as only punctuation after type. Titles hold never emoji and never exclamation and never extra punctuation.

## Scripting Rules and Structural Prompt

Scripts use rigid mode in pure native Bash with zero Python deps. Failures never suppress with blind true. Non critical steps use warn function for graceful degrade. User paths never hardcode and derive from home variable or home star paths. All operations run in foreground with zero background runner. All modifications to setup and verify remain strictly idempotent. Single source holds for each rule with never scattered copies. Shared modules serve several places. Zero placeholders and zero fallbacks and zero temporary solutions and zero regressions and zero hand written values. Specific file names and touched paths and launched commands and expected results in each change. Full contract lives in profile repo inside docs folder with structured prompt and shared contract and critical review.

# Agent Guidelines and Codebase Knowledge

## Project Overview

ai is the opt in AI debloat microcomponent for Omarchy on Arch Linux. Nothing here ever runs by default. Dedicated entry with request option is the only entry point, and module refuses to run with zero explicit flag set by entry.

## Ownership

Everything AI related always lives in this repo, never in sibling microcomponents. Covered holds TUI policy for AI CLI and standalone launcher removal and crash watch handling and agents plugin state. Sibling repos only reference this repo, never duplicate its logic.

## TUI Policy

TUI matches CLI. AI tools run inside the terminal, never in separate launcher windows, and always keep default appearance inherited from terminal. Zero theming and zero exceptions and zero custom UI configs.

## Scope Guardrails

Module never touches user managed AI CLI through mise and never touches tensaku which is screenshot annotator and never editors and never shell configs and never package owned files beyond listed AI launchers.

## Scripting Rules and Structural Prompt

Scripts use rigid mode in pure native Bash with zero Python deps. Failures never suppress with blind true. Non critical steps use warn function for graceful degrade. User paths never hardcode and derive from home star paths. All operations run in foreground with zero background runner. Single source holds for each rule with never scattered copies. Shared modules serve several places. Zero placeholders and zero fallbacks and zero temporary solutions and zero regressions and zero hand written values. Specific file names and touched paths and launched commands and expected results in each change. Full contract lives in profile repo inside docs folder with structured prompt and shared contract and critical review.

#!/bin/bash

# Self-contained integrity checks for the ai repo (no external test libs).

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
FAIL=0

ok() { PASS=$((PASS + 1)); printf '%s\n' "  pass $1"; }
bad() { FAIL=$((FAIL + 1)); printf '%s\n' "  fail $1"; }

contains() { grep -qE "$2" "$1" 2>/dev/null; }

printf '%s\n' "[ai integrity]"

[[ -f "$PROJECT_DIR/scripts/debloat-ai.sh" ]] && ok "entry exists" || bad "entry exists"
[[ -x "$PROJECT_DIR/scripts/debloat-ai.sh" ]] && ok "entry executable" || bad "entry executable"
[[ -f "$PROJECT_DIR/scripts/modules/40-ai.sh" ]] && ok "module exists" || bad "module exists"
[[ -x "$PROJECT_DIR/scripts/modules/40-ai.sh" ]] && ok "module executable" || bad "module executable"

contains "$PROJECT_DIR/scripts/modules/40-ai.sh" "OMACONF_AI_DEBLOAT" && ok "module gated by env flag" || bad "module gated by env flag"
contains "$PROJECT_DIR/scripts/modules/40-ai.sh" "mise" && ok "module excludes mise tools" || bad "module excludes mise tools"
contains "$PROJECT_DIR/scripts/modules/40-ai.sh" "tensaku" && ok "module excludes tensaku" || bad "module excludes tensaku"
contains "$PROJECT_DIR/scripts/modules/40-ai.sh" "omarchy-crash-watch" && ok "module handles crash-watch" || bad "module handles crash-watch"
contains "$PROJECT_DIR/scripts/modules/40-ai.sh" "omarchy.agents" && ok "module handles agents plugin" || bad "module handles agents plugin"
contains "$PROJECT_DIR/scripts/modules/40-ai.sh" "AI_LAUNCHERS" && ok "module removes AI launchers" || bad "module removes AI launchers"
contains "$PROJECT_DIR/scripts/modules/40-ai.sh" "opencode" && ok "module covers opencode" || bad "module covers opencode"
contains "$PROJECT_DIR/README.md" "inside the terminal" && ok "readme states terminal-only policy" || bad "readme states terminal-only policy"
contains "$PROJECT_DIR/scripts/debloat-ai.sh" "yes.*to apply" && ok "entry requires explicit yes" || bad "entry requires explicit yes"
contains "$PROJECT_DIR/scripts/debloat-ai.sh" "omarchy_as\(\)" && ok "entry defines omarchy_as" || bad "entry defines omarchy_as"

bash -n "$PROJECT_DIR/scripts/debloat-ai.sh" && ok "entry syntax valid" || bad "entry syntax valid"
bash -n "$PROJECT_DIR/scripts/modules/40-ai.sh" && ok "module syntax valid" || bad "module syntax valid"

"$PROJECT_DIR/scripts/debloat-ai.sh" 2>/dev/null | grep -q "opt-in" && ok "plan mode prints scope" || bad "plan mode prints scope"

printf '%s\n' "Total: $((PASS + FAIL)) | Passed: $PASS | Failed: $FAIL"
[[ $FAIL -eq 0 ]]

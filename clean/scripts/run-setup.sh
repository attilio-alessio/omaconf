#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG="$PROJECT_DIR/setup.log"

printf '%s\n' "Log: $LOG"
printf '\n'

sudo bash "$SCRIPT_DIR/setup.sh"

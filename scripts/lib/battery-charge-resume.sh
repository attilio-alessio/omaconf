#!/bin/bash
set -euo pipefail

[[ "${1:-}" == post ]] || exit 0
/usr/local/libexec/omaconf-set-battery-charge-limit

#!/bin/bash
set -euo pipefail

# Opt-in AI debloat. It runs only when sourced by scripts/debloat-ai.sh --yes,
# which sets OMACONF_AI_DEBLOAT=1. Requires log, warn and omarchy_as from the
# entry script. Default TUI of AI CLIs is never themed, no exceptions.
#
# Explicitly out of scope (never touched):
#   - user-managed AI CLIs (mise: opencode, copilot, agy, ...)
#   - tensaku (screenshot annotator, not AI)
#   - editor and shell configurations

if [[ "${OMACONF_AI_DEBLOAT:-0}" != "1" ]]; then
    printf '%s\n' "AI debloat is opt-in: run scripts/debloat-ai.sh --yes to proceed"
    return 0 2>/dev/null || exit 0
fi

AI_CRASH_UNITS=(
    omarchy-crash-watch.service
)

log "Disabling AI-assisted crash reporting"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _uid=$(id -u "$_user" 2>/dev/null || printf '')
    [[ -n "$_uid" && -d "/run/user/$_uid" ]] || { warn "no runtime dir for $_user; crash units skipped"; continue; }
    for unit in "${AI_CRASH_UNITS[@]}"; do
        sudo -u "$_user" env "XDG_RUNTIME_DIR=/run/user/$_uid" "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$_uid/bus" \
            systemctl --user disable --now "$unit" 2>/dev/null || warn "crash unit disable skipped for $_user"
        sudo -u "$_user" env "XDG_RUNTIME_DIR=/run/user/$_uid" "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$_uid/bus" \
            systemctl --user mask "$unit" 2>/dev/null || warn "crash unit mask skipped for $_user"
    done
done

log "Disabling omarchy agents plugin"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    omarchy_as "$_user" plugin disable omarchy.agents 2>/dev/null || warn "agents plugin disable skipped for $_user"
done

log "Removing standalone AI launchers (AI CLIs run inside the terminal only)"
AI_LAUNCHERS=(
    "*opencode*"
    "*copilot*"
    "*agy*"
    "*claude*"
    "*codex*"
    "*gemini*"
    "*aider*"
    "*ollama*"
)
for user_home in /home/*; do
    [[ -d "$user_home/.local/share/applications" ]] || continue
    for pattern in "${AI_LAUNCHERS[@]}"; do
        for entry in "$user_home"/.local/share/applications/$pattern.desktop; do
            [[ -f "$entry" ]] || continue
            rm -f "$entry" 2>/dev/null || warn "AI launcher removal skipped: $entry"
        done
    done
done
for pattern in "${AI_LAUNCHERS[@]}"; do
    for entry in /usr/share/applications/$pattern.desktop; do
        [[ -f "$entry" ]] || continue
        rm -f "$entry" 2>/dev/null || warn "system AI launcher removal skipped: $entry"
    done
done

log "AI debloat complete (opt-in)"

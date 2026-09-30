#!/usr/bin/env bash

set -euo pipefail

OMAMP_GIT="https://github.com/omaconf/omamp.git"
OMAMP_ID="krosci.omamp"

log "shell_plugins.install"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    if _plugin_list=$(omarchy_as "$_user" plugin list --json 2>/dev/null); then
        if grep -q "$OMAMP_ID" <<< "$_plugin_list"; then
            log "shell_plugins.present" "$_user"
        else
            omarchy_as "$_user" plugin add "$OMAMP_GIT" --enable --yes 2>/dev/null || warn "shell_plugins.add_skipped" "$_user"
        fi

        omarchy_as "$_user" bar move "$OMAMP_ID" --section right --index 0 2>/dev/null || warn "shell_plugins.bar_failed" "$_user"
    else
        warn "shell_plugins.list_unavailable" "$_user"
    fi
done

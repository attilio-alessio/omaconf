set -euo pipefail

log "theming.desktop"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _uid=$(id -u "$_user" 2>/dev/null) || continue

    if [[ -f "$user_home/.local/state/omarchy/current/theme.name" ]]; then
        _theme_name=$(tr '[:upper:]' '[:lower:]' < "$user_home/.local/state/omarchy/current/theme.name" | tr ' ' '-')
    else
        _theme_name="default"
    fi
    case "$_theme_name" in
        white|flexoki-light|catppuccin-latte|solarized-light) _icon_theme="Papirus" ;;
        *)                                                     _icon_theme="Papirus-Dark" ;;
    esac

    if [[ -e "/run/user/$_uid/bus" ]]; then
        user_as "$_user" gsettings set org.gnome.desktop.interface icon-theme "$_icon_theme" 2>/dev/null || warn "theming.icon_skipped" "$_user"
        user_as "$_user" gsettings set org.gnome.desktop.interface cursor-theme "capitaine-cursors" 2>/dev/null || warn "theming.cursor_skipped" "$_user"
    fi

    for _gtk_major in 3.0 4.0; do
        _gtk_dir="$user_home/.config/gtk-$_gtk_major"
        mkdir -p "$_gtk_dir"
        _gtk_settings="$_gtk_dir/settings.ini"
        if [[ ! -f "$_gtk_settings" ]]; then
            printf '[Settings]\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=capitaine-cursors\ngtk-cursor-theme-size=24\n' "$_icon_theme" > "$_gtk_settings"
        else
            sed -i '/^gtk-icon-theme-name=/d;/^gtk-cursor-theme-name=/d;/^gtk-cursor-theme-size=/d' "$_gtk_settings"
            printf 'gtk-icon-theme-name=%s\ngtk-cursor-theme-name=capitaine-cursors\ngtk-cursor-theme-size=24\n' "$_icon_theme" >> "$_gtk_settings"
        fi
        chown -R "$_user":"$_user" "$_gtk_dir" 2>/dev/null || warn "theming.gtk_chown" "$_user"
    done

    mkdir -p "$user_home/.icons/default"
    cat > "$user_home/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=default
Comment=Fallback cursor theme
Inherits=capitaine-cursors
EOF
    chown -R "$_user":"$_user" "$user_home/.icons" 2>/dev/null || warn "theming.icons_chown" "$_user"

    _hyland="$user_home/.config/hypr/hyprland.lua"
    if [[ -f "$_hyland" ]] && ! grep -q 'omablot cursor env' "$_hyland" 2>/dev/null; then
        cat >> "$_hyland" << 'LUAEOF'

-- omablot cursor env (managed)
hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("HYPRCURSOR_THEME", "capitaine-cursors")
-- end omablot cursor env (managed)
LUAEOF
        chown "$_user":"$_user" "$_hyland" 2>/dev/null || warn "theming.hypr_chown" "$_user"
    fi
done

log "theming.hooks"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _hook_dir="$user_home/.config/omarchy/hooks/theme-set.d"
    _i18n_dir="$user_home/.config/omarchy/hooks/i18n"
    mkdir -p "$_hook_dir" "$_i18n_dir/messages"
    for hook_file in "$PROJECT_DIR"/hooks/theme-set.d/*; do
        [[ -f "$hook_file" ]] || continue
        hook_name=$(basename "$hook_file")
        cp "$hook_file" "$_hook_dir/$hook_name"
        chmod +x "$_hook_dir/$hook_name"
        user_as "$_user" bash "$_hook_dir/$hook_name" 2>/dev/null || warn "theming.hook_failed" "$hook_name" "$_user"
    done
    cp "$PROJECT_DIR/scripts/lib/i18n.sh" "$PROJECT_DIR/scripts/lib/i18n-boot.sh" "$_i18n_dir/"
    cp "$PROJECT_DIR"/scripts/lib/messages/*.msg "$_i18n_dir/messages/"
    chmod 644 "$_i18n_dir/i18n.sh" "$_i18n_dir"/messages/*.msg
    chown -R "$_user":"$_user" "$_hook_dir" "$_i18n_dir"
done

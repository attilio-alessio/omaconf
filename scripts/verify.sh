#!/usr/bin/env bash


set -uo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

source "$SCRIPT_DIR/lib/i18n.sh"

i18n_init

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
    local desc="$1" condition="$2"
    if eval "$condition" &>/dev/null; then
        ((PASS++))
        echo -e "  ${GREEN}$(t verify.label_pass)${NC} $desc"
    else
        ((FAIL++))
        echo -e "  ${RED}$(t verify.label_fail)${NC} $desc"
    fi
}

section() { echo -e "\n${BOLD}$(t "$1")${NC}"; }

tcheck() {
    local key="$1" condition="$2"
    check "$(t "$key")" "$condition"
}

section verify.sec_packages
tcheck "check.pkg_installed"          "pacman -Q brave-origin-bin &>/dev/null"
tcheck "check.pkg_removed"                "! pacman -Q chromium &>/dev/null"
tcheck "check.pkg_installed"                "pacman -Q neovim &>/dev/null"
tcheck "check.pkg_installed"          "pacman -Q omarchy-nvim &>/dev/null"
tcheck "check.pkg_installed"                   "pacman -Q mpv &>/dev/null"
tcheck "check.pkg_installed"                  "pacman -Q yazi &>/dev/null"
tcheck "check.pkg_installed"                  "pacman -Q 7zip &>/dev/null"
tcheck "check.pkg_installed"                   "pacman -Q imv &>/dev/null"
tcheck "check.pkg_installed"             "pacman -Q trash-cli &>/dev/null"
tcheck "check.pkg_installed"               "pacman -Q zathura &>/dev/null"
tcheck "check.pkg_installed"     "pacman -Q zathura-pdf-mupdf &>/dev/null"
tcheck "check.pkg_removed"                "! pacman -Q nautilus &>/dev/null"
tcheck "check.pkg_removed"         "! pacman -Q yaru-icon-theme &>/dev/null"
tcheck "check.pkg_removed"   "! pacman -Q system-config-printer &>/dev/null"
tcheck "check.pkg_removed"                   "! pacman -Q totem &>/dev/null"
tcheck "check.pkg_removed"                  "! pacman -Q evince &>/dev/null"
tcheck "check.pkg_removed"                     "! pacman -Q eog &>/dev/null"
tcheck "check.pkg_removed"                 "! pacman -Q dolphin &>/dev/null"
tcheck "check.pkg_removed"                  "! pacman -Q okular &>/dev/null"
tcheck "check.pkg_removed"                "! pacman -Q gwenview &>/dev/null"
tcheck "check.pkg_removed"                "! pacman -Q kdenlive &>/dev/null"
tcheck "check.daemon_absent"            "! command -v dockerd &>/dev/null"
tcheck "check.runtime_present"                  "pacman -Q podman &>/dev/null"
tcheck "check.pkg_removed"              "! pacman -Q obs-studio &>/dev/null"
tcheck "check.pkg_removed"       "! pacman -Q libreoffice-fresh &>/dev/null"
tcheck "check.pkg_removed"                "! pacman -Q obsidian &>/dev/null"
tcheck "check.pkg_installed"                  "pacman -Q btop &>/dev/null"
tcheck "check.pkg_installed"     "pacman -Q capitaine-cursors &>/dev/null"
tcheck "check.pkg_installed"    "pacman -Q papirus-icon-theme &>/dev/null"
tcheck "check.pkg_removed"      "! pacman -Q gnome-disk-utility &>/dev/null"
tcheck "check.pkg_removed"      "! pacman -Q gnome-themes-extra &>/dev/null"

section verify.sec_gui
tcheck "check.tool_present"                   "pacman -Q herdr &>/dev/null"
tcheck "check.tool_present"                     "pacman -Q gum &>/dev/null"

section verify.sec_browser
tcheck "check.default_browser" "[[ \"\$(omarchy default browser 2>/dev/null)\" == brave-origin ]]"
tcheck "check.default_editor"  "[[ \"\$(cat \$HOME/.local/state/omarchy/defaults/editor 2>/dev/null)\" == micro ]]"
tcheck "check.yazi_config" "[[ -f \$HOME/.config/yazi/yazi.toml ]]"
tcheck "check.yazi_syntax_current" "grep -q '%s' \$HOME/.config/yazi/yazi.toml"
tcheck "check.yazi_syntax_legacy" "! grep -qF '\"\$@\"' \$HOME/.config/yazi/yazi.toml"



section verify.sec_firewall
if UFW_STATUS=$(sudo -n ufw status 2>/dev/null); then
    tcheck "check.ufw_active"          "echo '$UFW_STATUS' | grep -q 'Status: active'"
    tcheck "check.ufw_deny_incoming"       "sudo -n ufw status verbose 2>/dev/null | grep -q 'Default: deny (incoming)'"
    tcheck "check.ufw_allow_outgoing"      "sudo -n ufw status verbose 2>/dev/null | grep -q 'allow (outgoing)'"
else
    echo -e "  ${RED}$(t verify.label_skip)${NC} $(t verify.skip_root)"
fi
tcheck "check.ufw_boot"     "systemctl is-enabled ufw.service &>/dev/null"

section verify.sec_kernel
for setting in \
    "kernel.randomize_va_space	2" \
    "kernel.kptr_restrict	2" \
    "kernel.dmesg_restrict	1" \
    "kernel.perf_event_paranoid	3" \
    "kernel.unprivileged_bpf_disabled	1" \
    "kernel.yama.ptrace_scope	1" \
    "kernel.sysrq	16" \
    "fs.suid_dumpable	0" \
    "fs.protected_hardlinks	1" \
    "fs.protected_symlinks	1" \
    "fs.protected_fifos	2" \
    "fs.protected_regular	2" \
    "net.ipv4.conf.all.rp_filter	1" \
    "net.ipv4.conf.all.accept_redirects	0" \
    "net.ipv4.conf.all.send_redirects	0" \
    "net.ipv4.conf.all.accept_source_route	0" \
    "net.ipv4.icmp_echo_ignore_broadcasts	1" \
    "net.ipv4.tcp_syncookies	1" \
    "net.ipv4.tcp_rfc1337	1" \
    ; do
    key="${setting%%	*}"
    expected="${setting##*	}"
    check "$key = $expected" "[[ \"\$(cat /proc/sys/\${key//./\/})\" == $expected ]]"
done
tcheck "check.sysctl_persisted"         "[[ -f /etc/sysctl.d/99-security.conf ]]"
tcheck "check.coredump_disabled"             "[[ -f /etc/security/limits.d/99-no-core.conf ]]"

section verify.sec_pam
tcheck "check.faillock"    "[[ -f /etc/security/faillock.conf ]]"
tcheck "check.pwquality"   "[[ -f /etc/security/pwquality.conf ]]"
tcheck "check.access_conf" "[[ -f /etc/security/access.conf ]] && grep -q 'ALL:ALL' /etc/security/access.conf"

section verify.sec_ssh
SSHD_DIR="/etc/ssh/sshd_config.d"
if [[ -r "$SSHD_DIR/hardened.conf" ]]; then
    tcheck "check.sshd_hardened"        "[[ -f $SSHD_DIR/hardened.conf ]]"
    tcheck "check.sshd_root_login"     "grep -q '^PermitRootLogin no' $SSHD_DIR/hardened.conf"
    tcheck "check.sshd_password_auth"  "grep -q '^PasswordAuthentication no' $SSHD_DIR/hardened.conf"
elif sudo -n test -r "$SSHD_DIR/hardened.conf" 2>/dev/null; then
    tcheck "check.sshd_hardened"        "sudo -n test -f $SSHD_DIR/hardened.conf"
    tcheck "check.sshd_root_login"     "sudo -n grep -q '^PermitRootLogin no' $SSHD_DIR/hardened.conf"
    tcheck "check.sshd_password_auth"  "sudo -n grep -q '^PasswordAuthentication no' $SSHD_DIR/hardened.conf"
else
    echo -e "  ${RED}$(t verify.label_skip)${NC} $(t verify.skip_ssh)"
fi

section verify.sec_services
tcheck "check.avahi_disabled"   "! systemctl is-enabled avahi-daemon.service 2>/dev/null | grep -q '^enabled$'"
tcheck "check.cups_disabled"           "! systemctl is-enabled cups.service 2>/dev/null | grep -q '^enabled$'"
tcheck "check.bluetooth_enabled"       "systemctl is-enabled bluetooth.service 2>/dev/null | grep -q '^enabled$'"
tcheck "check.sshd_service_hardened"   "[[ -f /etc/systemd/system/sshd.service.d/hardened.conf ]]"
tcheck "check.networkmanager_intact" "! [[ -f /etc/NetworkManager/conf.d/security.conf ]]"
tcheck "check.resolved_hardened" "[[ -f /etc/systemd/resolved.conf.d/hardened.conf ]]"

section verify.sec_tooling
for pkg in lynis rkhunter clamav audit usbguard fail2ban apparmor; do
    check "$pkg present" "pacman -Q $pkg &>/dev/null"
done
tcheck "check.apparmor_kernel" "grep -Eq '(^| )lsm=[^ ]*apparmor[^ ]*( |$)' /proc/cmdline && [[ -r /sys/kernel/security/apparmor/profiles ]]"

section verify.sec_perms
tcheck "check.perm_root"       "[[ \"\$(stat -c %a /root)\" == 700 ]]"
tcheck "check.perm_shadow" "[[ \"\$(stat -c %a /etc/shadow)\" == 600 ]]"
tcheck "check.perm_gshadow" "[[ \"\$(stat -c %a /etc/gshadow)\" == 600 ]]"
tcheck "check.perm_passwd" "[[ \"\$(stat -c %a /etc/passwd)\" == 644 ]]"
tcheck "check.perm_group"  "[[ \"\$(stat -c %a /etc/group)\" == 644 ]]"

section verify.sec_modules
tcheck "check.usb_storage_blocked"      "[[ -f /etc/modprobe.d/disable-usb-storage.conf ]]"
tcheck "check.protocols_blocked" "[[ -f /etc/modprobe.d/disable-protocols.conf ]]"
tcheck "check.firewire_blocked"         "[[ -f /etc/modprobe.d/disable-firewire.conf ]]"
tcheck "check.filesystems_blocked" "[[ -f /etc/modprobe.d/disable-ramfs.conf ]]"

section verify.sec_health
tcheck "check.tpm_verity_removed" "! [[ -f /usr/lib/nvpcr/verity.nvpcr ]]"
tcheck "check.voxtype_inactive" "! systemctl --user is-active voxtype 2>/dev/null | grep -q '^active$'"
tcheck "check.kitty_terminal" "pacman -Q kitty &>/dev/null && ! pacman -Q foot &>/dev/null"
tcheck "check.webapps_removed" "! grep -rlE 'omarchy-(launch-webapp|webapp-handler)' /usr/share/omarchy/applications 2>/dev/null"

section verify.sec_power
tcheck "check.power_conf" "[[ -f /etc/omaconf/power.conf ]]"
tcheck "check.battery_udev" "[[ -f /etc/udev/rules.d/98-battery-charge-threshold.rules ]]"
tcheck "check.battery_tmpfiles" "[[ -f /etc/tmpfiles.d/battery-charge-threshold.conf ]]"
tcheck "check.battery_service" "systemctl is-enabled battery-charge-threshold.service &>/dev/null || [[ -L /etc/systemd/system/multi-user.target.wants/battery-charge-threshold.service ]]"
if ls /sys/class/power_supply/BAT*/charge_control_end_threshold &>/dev/null; then
    tcheck "check.battery_limit" "grep -qx '75' /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null"
fi
if [[ -r /sys/power/mem_sleep ]]; then
    if grep -q '\[deep\]' /sys/power/mem_sleep; then
        tcheck "check.suspend_conf" "grep -q '^MemorySleepMode=deep$' /etc/systemd/sleep.conf.d/99-omaconf-suspend.conf"
    elif grep -q '\[s2idle\]' /sys/power/mem_sleep; then
        tcheck "check.suspend_conf" "grep -q '^MemorySleepMode=s2idle$' /etc/systemd/sleep.conf.d/99-omaconf-suspend.conf"
    else
        tcheck "check.suspend_conf" "[[ -f /etc/systemd/sleep.conf.d/99-omaconf-suspend.conf ]]"
    fi
fi

section verify.sec_sched
if [[ -r /etc/cron.weekly/security-audit.sh ]]; then
    tcheck "check.weekly_audit" "[[ -f /etc/cron.weekly/security-audit.sh && -x /etc/cron.weekly/security-audit.sh ]]"
elif sudo -n test -r /etc/cron.weekly/security-audit.sh 2>/dev/null; then
    tcheck "check.weekly_audit" "sudo -n test -f /etc/cron.weekly/security-audit.sh && sudo -n test -x /etc/cron.weekly/security-audit.sh"
else
    echo -e "  ${RED}$(t verify.label_skip)${NC} $(t verify.skip_audit)"
fi

section verify.sec_userconfigs
tcheck "check.starship_config"  "[[ -f \$HOME/.config/starship.toml ]]"
tcheck "check.git_config"       "[[ -f \$HOME/.config/git/config ]]"
tcheck "check.lazygit_config"   "[[ -f \$HOME/.config/lazygit/config.yml ]]"

section verify.sec_debloat
tcheck "check.ignorepkg" "grep -q '^IgnorePkg' /etc/pacman.conf"
tcheck "check.icon_theme"      "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | grep -q 'Papirus'"
tcheck "check.cursor_theme"  "gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | grep -q 'capitaine-cursors'"
tcheck "check.no_tela"         "! grep -rq 'Tela' $HOME/.config/omarchy/themes/ 2>/dev/null"
tcheck "check.folder_color_hook"        "[[ -x $HOME/.config/omarchy/hooks/theme-set.d/folder-color ]]"
tcheck "check.micro_theme_hook"         "[[ -x $HOME/.config/omarchy/hooks/theme-set.d/micro-theme ]]"
tcheck "check.micro_colorscheme" "[[ -f $HOME/.config/micro/colorschemes/omarchy.micro ]]"

section verify.sec_aur
tcheck "check.no_unverified_aur" "! grep -q 'aur_install ' '$SCRIPT_DIR/setup.sh'"
tcheck "check.no_yay"   "! grep -q 'yay -S' '$SCRIPT_DIR/setup.sh'"

section verify.sec_locale
VERIFY_LANG=$(sed -n 's/^LANG=//p' /etc/locale.conf 2>/dev/null | head -1)

locale_generated() {
    local want have
    want=$(printf '%s' "$VERIFY_LANG" | tr '[:upper:]' '[:lower:]' | tr -d '-')
    have=$(locale -a 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '-')
    [[ -n "$want" ]] && grep -qxF "$want" <<< "$have"
}
tcheck "verify.locale_conf"  "[[ -f /etc/locale.conf ]]"
tcheck "verify.locale_lang"  "[[ -n \"$VERIFY_LANG\" ]]"
tcheck "verify.locale_keymap" "grep -qE '^KEYMAP=' /etc/vconsole.conf 2>/dev/null"
tcheck "verify.locale_generated" "locale_generated"
tcheck "verify.locale_profile" "[[ -f /etc/profile.d/omaconf-locale.sh ]]"
tcheck "verify.locale_hyprland" "grep -rq 'kb_layout' /home/*/.config/hypr/input.lua 2>/dev/null"
catalog_check() {
    local lang
    for lang in en it fr de es pt; do
        [[ -f "$SCRIPT_DIR/lib/messages/$lang.msg" ]] || return 1
    done
    return 0
}
tcheck "verify.locale_catalogs" "catalog_check"
tcheck "verify.locale_i18n" "[[ -n \"$I18N_LANG\" ]] && (( ${#OMACONF_I18N[@]} > 0 ))"

echo ""
echo -e "${BOLD}$(t verify.passed_summary "$PASS" "$FAIL")${NC}"
[[ $FAIL -eq 0 ]] || exit 1

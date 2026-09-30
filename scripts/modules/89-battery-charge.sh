#!/usr/bin/env bash

set -euo pipefail

log "power.charge"
mkdir -p /etc/omaconf
chmod 755 /etc/omaconf 2>/dev/null || warn "power.omaconf_chmod"
printf '%s\n' 'BATTERY_CHARGE_LIMIT=75' > /etc/omaconf/power.conf
chmod 644 /etc/omaconf/power.conf

cat > /etc/udev/rules.d/98-battery-charge-threshold.rules << 'UDEV'
ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*|BATT*", ATTR{charge_control_end_threshold}=="?*", ATTR{charge_control_end_threshold}="75"
ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*|BATT*", ATTR{charge_stop_threshold}=="?*", ATTR{charge_stop_threshold}="75"
ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*|BATT*", ATTR{charge_end_threshold}=="?*", ATTR{charge_end_threshold}="75"
UDEV
chmod 644 /etc/udev/rules.d/98-battery-charge-threshold.rules
install -Dm755 "$PROJECT_ROOT/scripts/lib/set-battery-charge-limit.sh" /usr/local/libexec/omaconf-set-battery-charge-limit
install -Dm755 "$PROJECT_ROOT/scripts/lib/battery-charge-resume.sh" /usr/lib/systemd/system-sleep/omaconf-battery-charge-limit
udevadm control --reload-rules 2>/dev/null || warn "power.udev_reload_skipped"
udevadm trigger --subsystem-match=power_supply 2>/dev/null || warn "power.udev_trigger_skipped"

mkdir -p /etc/tmpfiles.d
cat > /etc/tmpfiles.d/battery-charge-threshold.conf << 'TMPFILES'
w- /sys/class/power_supply/*/charge_control_end_threshold - - - - 75
w- /sys/class/power_supply/*/charge_stop_threshold - - - - 75
w- /sys/class/power_supply/*/charge_end_threshold - - - - 75
TMPFILES
chmod 644 /etc/tmpfiles.d/battery-charge-threshold.conf
systemd-tmpfiles --create /etc/tmpfiles.d/battery-charge-threshold.conf 2>/dev/null || warn "power.tmpfiles_skipped"

cat > /etc/systemd/system/battery-charge-threshold.service << 'SERVICE'
[Unit]
Description=Universal Battery Charge Threshold Policy
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/libexec/omaconf-set-battery-charge-limit

[Install]
WantedBy=multi-user.target
SERVICE
chmod 644 /etc/systemd/system/battery-charge-threshold.service
systemctl daemon-reload 2>/dev/null || warn "power.daemon_reload_skipped"
systemctl enable battery-charge-threshold.service 2>/dev/null || warn "power.charge_enable_skipped"
systemctl start battery-charge-threshold.service 2>/dev/null || warn "power.charge_start_skipped"

/usr/local/libexec/omaconf-set-battery-charge-limit || warn "power.charge_write_failed" "supported battery threshold"

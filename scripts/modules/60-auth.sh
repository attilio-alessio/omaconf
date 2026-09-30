set -euo pipefail

log "auth.pam"
cat > /etc/security/faillock.conf << 'FAILLOCK'
deny = 5
unlock_time = 900
FAILLOCK
chmod 644 /etc/security/faillock.conf

cat > /etc/security/pwquality.conf << 'PWQ'
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
difok = 5
minclass = 4
PWQ
chmod 644 /etc/security/pwquality.conf

log "auth.access"
cat > /etc/security/access.conf << 'ACCESS'
+:root:LOCAL
+:root:ALL
+:wheel:LOCAL
+:wheel:ALL
+:sddm:LOCAL
+:sddm:ALL
+:gdm:LOCAL
+:gdm:ALL
+:greetd:LOCAL
+:greetd:ALL
+:lightdm:LOCAL
+:lightdm:ALL
-:ALL:ALL
ACCESS
chmod 644 /etc/security/access.conf

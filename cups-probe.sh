#!/bin/sh
# Probe a machine that has BOTH the CUPS deb and the CUPS snap installed, and
# report which one owns printing. Run as: sudo ./cups-probe.sh
# Safe: read-only, no config changes, no service restarts.

USERHOME=$(getent passwd "${SUDO_USER:-$(id -un)}" | cut -d: -f6)

sec() { printf '\n========== %s ==========\n' "$1"; }

sec "versions installed"
dpkg -l 2>/dev/null | grep -E '^ii\s+(cups|libcups)' | awk '{print "deb  ", $2, $3}'
snap list cups 2>/dev/null | tail -n +2 | awk '{print "snap  cups", $2, "rev", $3}'

sec "daemons running (start time matters - mode is decided at snap start)"
ps -eo pid,ppid,lstart,args | grep -E '[c]upsd|[c]ups-browsed|[c]ups-proxyd'

sec "who owns port 631"
ss -lntp 2>/dev/null | grep -E 'Local|:631'

sec "who owns which cups.sock (note the inode; a replaced path is a silent handover)"
ss -lxp 2>/dev/null | grep -E 'cups.sock'

sec "snap mode"
printf 'proxy-mode marker : '; ls /var/snap/cups/current/var/run/proxy-mode 2>&1
printf 'no-proxy override : '; ls /var/snap/cups/common/no-proxy 2>&1
printf 'cups-proxyd pid   : '; cat /var/snap/cups/current/var/run/cups-proxyd.pid 2>&1; echo
echo "snap client.conf  :"; sed 's/^/    /' /var/snap/cups/common/etc/cups/client.conf 2>&1
echo "  ServerName /run/cups/cups.sock                 => standalone"
echo "  ServerName /var/snap/cups/common/run/cups.sock => proxy or parallel"
echo "snap cupsd.conf Listen/Port lines:"
grep -E '^[[:space:]]*(Listen|Port)' /var/snap/cups/common/etc/cups/cupsd.conf 2>&1 | sed 's/^/    /'

sec "deb side"
systemctl is-active   cups cups.socket cups-browsed 2>&1 | paste -sd' '
systemctl is-enabled  cups cups.socket cups-browsed 2>&1 | paste -sd' '
printf '/etc/cups/cupsd.conf readable (this is what triggers proxy mode): '
test -r /etc/cups/cupsd.conf && echo YES || echo no
echo "deb cupsd.conf Listen/Port lines:"
grep -E '^[[:space:]]*(Listen|Port)' /etc/cups/cupsd.conf 2>&1 | sed 's/^/    /'

sec "the three client.conf files, in libcups search order"
for f in "$USERHOME/.cups/client.conf" /etc/cups/client.conf \
         /var/snap/cups/common/etc/cups/client.conf; do
    printf -- '--- %s\n' "$f"
    if [ -r "$f" ]; then sed 's/^/    /' "$f"; else echo "    (absent)"; fi
done
echo "NOTE: \$HOME/.cups/client.conf is tried FIRST by both libcups builds and"
echo "      there is no fallback if it opens. /etc/cups is the deb's; /var/snap"
echo "      is the snap's. SSLOptions must be in whichever one owns printing."

sec "queues - names can match while DeviceURIs differ"
echo "--- deb view (/usr/bin/lpstat)"; /usr/bin/lpstat -v 2>&1 | sed 's/^/    /'
printf '    default: '; /usr/bin/lpstat -d 2>&1
echo "--- snap view (cups.lpstat)";   cups.lpstat -v 2>&1 | sed 's/^/    /'
printf '    default: '; cups.lpstat -d 2>&1
echo "A proxy:// DeviceURI means that queue is a mirror of the deb's, made by"
echo "cups-proxyd. The real device URI - and the real TLS - lives on the deb."

sec "which libcups each toolchain uses"
printf 'snap serverroot: '; /snap/cups/current/bin/cups-config --serverroot 2>&1
printf 'snap libcups   : '; /snap/cups/current/bin/cups-config --version 2>&1
printf 'deb  libcups   : '; dpkg -l libcups2t64 2>/dev/null | awk '/^ii/{print $3}'
echo "deb  ipptool   : $(command -v ipptool)"
echo "snap ipptool   : $(command -v cups.ipptool)"

sec "gnutls system config (applies to both, snap included)"
cat /etc/gnutls/config 2>&1 | sed 's/^/    /'

sec "backends (each links its own libcups, so each reads its own client.conf)"
ls /usr/lib/cups/backend/ipp /usr/lib/cups/backend/ipps 2>&1
ls /snap/cups/current/lib/cups/backend/ipp /snap/cups/current/lib/cups/backend/ipps 2>&1

sec "logs - whichever one moves during a job is the owner"
echo "--- deb  /var/log/cups/error_log"
tail -n 15 /var/log/cups/error_log 2>&1 | sed 's/^/    /'
echo "--- snap /var/snap/cups/current/var/log/error_log"
tail -n 15 /var/snap/cups/current/var/log/error_log 2>&1 | sed 's/^/    /'
echo "--- snap /var/snap/cups/current/var/log/cups-browsed_log"
tail -n 5 /var/snap/cups/current/var/log/cups-browsed_log 2>&1 | sed 's/^/    /'

printf '\n========== done ==========\n'

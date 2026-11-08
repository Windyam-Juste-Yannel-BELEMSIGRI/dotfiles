#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase2-network-root.sh — migration ifupdown → NetworkManager (wlo1)  │
# │ Usage : sudo phase2-network-root.sh [--dry-run] [-h]                  │
# │ 1. sauvegarde /etc/network + /etc/NetworkManager                     │
# │ 2. installe packages/20-network.list (NM ignore wlo1 tant qu'il est  │
# │    déclaré dans interfaces → aucune coupure)                         │
# │ 3. lit SSID/PSK de wlo1 (wpa-ssid/wpa-psk ou wpa-conf) et écrit un    │
# │    profil keyfile 600 (/etc/NetworkManager/system-connections) ;     │
# │    la clé n'est jamais affichée ni passée en argument                │
# │ 4. bascule dans une unité transitoire avec GARDE-FOU : si aucun ping │
# │    ne passe en 60 s, restauration automatique d'ifupdown              │
# │ Retour arrière manuel : system/network-rollback-root.sh              │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,13p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
DRY=0
case ${1:-} in -h|--help) usage; exit 0 ;; --dry-run) DRY=1 ;; "") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }

here=$(cd "$(dirname "$0")" && pwd)
IFACE=wlo1
IFS_FILE=/etc/network/interfaces
ts=$(date +%Y%m%d-%H%M%S)
bk=/var/backups/setup-sway/$ts-network
CON_NAME=wifi-$IFACE-migrated

log() { printf '[phase2] %s\n' "$*"; }
ping_ok() { ping -c1 -W2 -I "$IFACE" 9.9.9.9 >/dev/null 2>&1 || ping -c1 -W2 deb.debian.org >/dev/null 2>&1; }

# ── 0. état initial ─────────────────────────────────────────────────────
log "interfaces (clé masquée) :"
sed -E 's/^([[:space:]]*wpa-psk[[:space:]]+).*/\1********/' "$IFS_FILE" | sed 's/^/    /'
if ping_ok; then log "connectivité AVANT : OK"; else log "connectivité AVANT : KO (on continue sans bascule)"; fi

# ── 1. sauvegarde ──────────────────────────────────────────────────────
if (( ! DRY )); then
  install -d -m 700 "$bk"
  dirs=(etc/network); [[ -d /etc/NetworkManager ]] && dirs+=(etc/NetworkManager)
  tar -czpf "$bk/etc-network.tar.gz" -C / "${dirs[@]}"
  cp -a "$IFS_FILE" "$bk/interfaces.orig"
  log "sauvegarde : $bk"
fi

# ── 2. paquets ─────────────────────────────────────────────────────────
dry=(); (( DRY )) && dry=(--dry-run)
"$here/apt-install.sh" "${dry[@]}" "$here/packages/20-network.list"

# ── 3. extraction SSID / PSK ───────────────────────────────────────────
ssid=$(awk -v i="$IFACE" '$1=="iface"{cur=$2} cur==i && $1=="wpa-ssid"{ $1=""; sub(/^ /,""); print; exit}' "$IFS_FILE")
psk=$(awk -v i="$IFACE" '$1=="iface"{cur=$2} cur==i && $1=="wpa-psk"{print $2; exit}' "$IFS_FILE")
conf=$(awk -v i="$IFACE" '$1=="iface"{cur=$2} cur==i && $1=="wpa-conf"{print $2; exit}' "$IFS_FILE")
if [[ -z $ssid && -n $conf && -r $conf ]]; then
  ssid=$(sed -nE 's/^[[:space:]]*ssid="?([^"]*)"?/\1/p' "$conf" | head -1)
  psk=$(sed -nE 's/^[[:space:]]*psk="?([^"]*)"?/\1/p' "$conf" | head -1)
fi
ssid=${ssid%\"}; ssid=${ssid#\"}; psk=${psk%\"}; psk=${psk#\"}
[[ -n $ssid ]] || { log "SSID introuvable pour $IFACE → ARRÊT (rien n'a été basculé)"; exit 2; }
log "SSID détecté : $ssid ; clé : $([[ -n $psk ]] && echo présente || echo absente)"

if (( DRY )); then
  log "(dry-run) écrirait /etc/NetworkManager/system-connections/$CON_NAME.nmconnection (600)"
  log "(dry-run) commenterait le bloc $IFACE de $IFS_FILE puis basculerait avec garde-fou"
  exit 0
fi

# ── 4. profil NetworkManager (keyfile) ─────────────────────────────────
kf=/etc/NetworkManager/system-connections/$CON_NAME.nmconnection
umask 077
{
  echo "[connection]"; echo "id=$CON_NAME"; echo "type=wifi"; echo "interface-name=$IFACE"
  echo "autoconnect=true"; echo "autoconnect-priority=10"
  echo; echo "[wifi]"; echo "mode=infrastructure"; echo "ssid=$ssid"
  if [[ -n $psk ]]; then
    echo; echo "[wifi-security]"; echo "key-mgmt=wpa-psk"; echo "psk=$psk"
  fi
  echo; echo "[ipv4]"; echo "method=auto"
  echo; echo "[ipv6]"; echo "addr-gen-mode=stable-privacy"; echo "method=auto"
} > "$kf"
chmod 600 "$kf"; chown root:root "$kf"
unset psk
nmcli connection reload
log "profil NM créé : $kf (600)"

# ── 5. bascule avec garde-fou (unité transitoire, survit à la session) ──
SW=$bk/nm-switch.sh   # /run est monté noexec : script lancé via /bin/bash
cat > "$SW" <<EOF
#!/usr/bin/env bash
set -u
log() { logger -t setup-sway "\$*"; echo "\$*"; }
ping_ok() { ping -c1 -W2 9.9.9.9 >/dev/null 2>&1 || ping -c1 -W2 deb.debian.org >/dev/null 2>&1; }
ifdown $IFACE || true
# commente toutes les lignes du/des bloc(s) $IFACE (auto/allow-hotplug/iface + options)
awk -v i="$IFACE" '
  /^[[:space:]]*(auto|allow-hotplug)[[:space:]]/ { n=0; for(k=2;k<=NF;k++) if(\$k==i) n=1; if(n){print "#setup-sway# " \$0; next} }
  /^iface[[:space:]]/ { inb=(\$2==i) }
  /^[^[:space:]#]/ && !/^iface[[:space:]]/ { inb=0 }
  inb { print "#setup-sway# " \$0; next }
  { print }' "$bk/interfaces.orig" > $IFS_FILE.new
chmod 600 $IFS_FILE.new && mv $IFS_FILE.new $IFS_FILE
systemctl restart NetworkManager
sleep 3
nmcli device set $IFACE managed yes || true
nmcli connection up id "$CON_NAME" || true
for t in \$(seq 1 30); do
  if ping_ok; then log "bascule NetworkManager OK après \$((t*2)) s"; exit 0; fi
  sleep 2
done
log "ÉCHEC : pas de connectivité via NM → restauration ifupdown"
nmcli device set $IFACE managed no || true
cp -a "$bk/interfaces.orig" $IFS_FILE
systemctl restart NetworkManager
ifup $IFACE || true
exit 1
EOF
chmod 700 "$SW"
log "bascule en cours (coupure de quelques secondes)…"
rc=0
systemd-run --unit="setup-sway-nm-switch-$ts" --wait --collect --quiet /bin/bash "$SW" || rc=$?
case $rc in
  0) log "✔ $IFACE est géré par NetworkManager" ;;
  1) log "✖ bascule annulée par le garde-fou : ifupdown restauré" ;;
  *) log "✖ l'unité de bascule n'a pas pu s'exécuter (code $rc) : aucune modification" ;;
esac
journalctl -q -t setup-sway -n 5 --no-pager || true
nmcli -f GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS device show "$IFACE" || true
if ping_ok; then log "connectivité APRÈS : OK"; else log "connectivité APRÈS : KO"; fi

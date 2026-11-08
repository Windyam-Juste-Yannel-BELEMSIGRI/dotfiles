#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ network-rollback-root.sh — retour à ifupdown pour wlo1               │
# │ Usage : sudo network-rollback-root.sh [SAUVEGARDE] [-h]              │
# │   SAUVEGARDE : dossier /var/backups/setup-sway/<ts>-network          │
# │                (par défaut : le plus récent)                          │
# │ Restaure /etc/network/interfaces, rend wlo1 à ifupdown (NM le laisse │
# │ "unmanaged"), relance ifup. NetworkManager reste installé ;           │
# │ pour le retirer : sudo apt purge network-manager (après vérification).│
# │ Utilisable depuis un TTY sans interface graphique.                    │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,10p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
[[ ${1:-} == -h || ${1:-} == --help ]] && { usage; exit 0; }
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }

IFACE=wlo1
bk=${1:-$(find /var/backups/setup-sway -maxdepth 1 -type d -name '*-network' | sort | tail -1)}
[[ -f $bk/interfaces.orig ]] || { echo "sauvegarde introuvable : ${bk:-?}" >&2; exit 1; }

echo "restauration depuis $bk"
nmcli connection down id "wifi-$IFACE-migrated" 2>/dev/null || true
nmcli device set "$IFACE" managed no 2>/dev/null || true
cp -a "$bk/interfaces.orig" /etc/network/interfaces
systemctl restart NetworkManager 2>/dev/null || true
ifup "$IFACE" || true
sleep 3
ip -br addr show "$IFACE"
ping -c1 -W3 deb.debian.org >/dev/null && echo "connectivité : OK" || echo "connectivité : KO"

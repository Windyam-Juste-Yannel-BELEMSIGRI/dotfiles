#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase11-battery-root.sh — limite de charge batterie (ASUS, 80 %)     │
# │ Usage : sudo phase11-battery-root.sh [SEUIL] [-h]   (défaut 80)       │
# │ Écrit BAT0/charge_control_end_threshold maintenant, au démarrage et  │
# │ après chaque mise en veille (le firmware ASUS le remet parfois à     │
# │ 100 au réveil) via battery-charge-limit.service.                     │
# │ Annulation : sudo battery-rollback-root.sh                           │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,8p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
case ${1:-} in -h|--help) usage; exit 0 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
log() { printf '[batterie] %s\n' "$*"; }

LIMIT=${1:-80}
if ! [[ $LIMIT =~ ^[0-9]+$ ]] || (( LIMIT < 40 || LIMIT > 100 )); then echo "seuil invalide : $LIMIT (40-100)" >&2; exit 1; fi
ATTR=/sys/class/power_supply/BAT0/charge_control_end_threshold
[[ -w $ATTR ]] || { echo "$ATTR absent : firmware non compatible" >&2; exit 1; }

cat > /etc/systemd/system/battery-charge-limit.service <<EOF
[Unit]
Description=Limite de charge batterie à ${LIMIT} %% (durabilité)
After=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo ${LIMIT} > ${ATTR}'

[Install]
WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
EOF

systemctl daemon-reload
systemctl enable --now battery-charge-limit.service
log "✔ seuil actuel : $(<"$ATTR") %"

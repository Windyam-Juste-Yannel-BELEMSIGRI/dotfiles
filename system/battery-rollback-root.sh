#!/usr/bin/env bash
# battery-rollback-root.sh — supprime la limite de charge (retour à 100 %).
# Usage : sudo battery-rollback-root.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
systemctl disable --now battery-charge-limit.service 2>/dev/null || true
rm -f /etc/systemd/system/battery-charge-limit.service
systemctl daemon-reload
echo 100 > /sys/class/power_supply/BAT0/charge_control_end_threshold
echo "[batterie] ✔ limite retirée (100 %)"

#!/usr/bin/env bash
# apps-rollback-root.sh — annule phase13 (simulation par défaut).
# Usage : sudo apps-rollback-root.sh [--apply]
#   Supprime les paquets de packages/95-apps.list, le dépôt VirtualBox,
#   l'épinglage, le réglage KVM et la politique Chromium. Les VM
#   (~/VirtualBox VMs) et profils (~/.config/chromium) sont conservés.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$here/packages/95-apps.list" | awk '{print $1}')
if [[ ${1:-} != --apply ]]; then
  apt-get -s purge "${pkgs[@]}" | grep -E '^Purg' || true
  echo "(simulation) relancer avec --apply pour exécuter"; exit 0
fi
apt-get purge -y "${pkgs[@]}"
apt-get autoremove --purge -y
extrepo disable virtualbox 2>/dev/null || true
rm -f /etc/apt/sources.list.d/extrepo_virtualbox.sources /etc/apt/preferences.d/virtualbox.pref \
      /etc/modprobe.d/glass-soc-kvm.conf /etc/chromium/policies/managed/glass-soc.json
gpasswd -d "${SUDO_USER:-}" vboxusers 2>/dev/null || true
apt-get update -q
echo "[apps] ✔ applications de la phase 13 retirées"

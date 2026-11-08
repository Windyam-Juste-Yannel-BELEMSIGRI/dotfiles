#!/usr/bin/env bash
# devtools-rollback-root.sh — annule phase12 (simulation par défaut).
# Usage : sudo devtools-rollback-root.sh [--apply]
#   Supprime les paquets de packages/90-dev.list, le dépôt VS Code (extrepo),
#   l'épinglage, /etc/docker/daemon.json, et retire l'utilisateur des groupes
#   docker et wireshark. Les images/volumes Docker (/var/lib/docker) sont
#   conservés : supprime-les à la main si tu le souhaites.
#   Côté utilisateur : dev-setup --remove.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$here/packages/90-dev.list" | awk '{print $1}')
if [[ ${1:-} != --apply ]]; then
  apt-get -s purge "${pkgs[@]}" | grep -E '^Purg' || true
  echo "(simulation) relancer avec --apply pour exécuter"; exit 0
fi
systemctl disable --now docker.socket docker.service containerd.service 2>/dev/null || true
apt-get purge -y "${pkgs[@]}"
apt-get autoremove --purge -y
extrepo disable vscode 2>/dev/null || true
rm -f /etc/apt/sources.list.d/extrepo_vscode.sources /etc/apt/preferences.d/vscode.pref /etc/docker/daemon.json
for g in docker wireshark; do gpasswd -d "${SUDO_USER:-}" "$g" 2>/dev/null || true; done
apt-get update -q
echo "[dev] ✔ outils de la phase 12 retirés"

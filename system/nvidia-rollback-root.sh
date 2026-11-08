#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ nvidia-rollback-root.sh — retire le pilote NVIDIA, retour à nouveau  │
# │ Usage : sudo nvidia-rollback-root.sh [--apply] [-h]                   │
# │   sans --apply : SIMULATION de la purge (lecture seule)               │
# │ Purge les paquets nvidia/libnvidia/firmware-nvidia-gsp, supprime      │
# │ /etc/modprobe.d/nvidia-drm-setup-sway.conf, retire "non-free" de      │
# │ sources.list, régénère l'initramfs. Utilisable depuis un TTY.         │
# │ Sway n'est pas concerné : il tourne sur l'iGPU Intel.                 │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,9p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
case ${1:-} in -h|--help) usage; exit 0 ;; --apply|"") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }

mapfile -t pk < <(dpkg-query -W -f='${Package} ${Status}\n' 'nvidia-*' 'libnvidia-*' 'firmware-nvidia-gsp' 'xserver-xorg-video-nvidia' 'libcuda1' 2>/dev/null \
  | awk '$NF=="installed"{print $1}')
(( ${#pk[@]} )) || { echo "aucun paquet NVIDIA installé"; exit 0; }
sim=$(apt-get -s purge "${pk[@]}")
grep -E '^Purg|^Remv' <<<"$sim" | sed 's/^/  /'
if grep -E '^(Purg|Remv) ' <<<"$sim" | grep -qE ' (sway|systemd|linux-image|grub|network-manager|sudo)[ :]'; then
  echo "✖ la purge toucherait un paquet critique : ARRÊT"; exit 2
fi
[[ ${1:-} == --apply ]] || { echo "(simulation) relancer avec --apply"; exit 0; }

apt-get purge -y "${pk[@]}"
rm -f /etc/modprobe.d/nvidia-drm-setup-sway.conf
sed -i -E '/^deb(-src)? .*debian/ s/ non-free( |$)/\1/' /etc/apt/sources.list
apt-get update -qq
update-initramfs -u -k all
echo "✔ NVIDIA retiré ; redémarrer (nouveau reprendra la main)."

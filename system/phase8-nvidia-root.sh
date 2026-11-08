#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase8-nvidia-root.sh — pilote NVIDIA (RTX 4060) depuis Debian 13    │
# │ Usage : sudo phase8-nvidia-root.sh [--dry-run] [-h]                   │
# │ 1. sauvegarde /etc/apt + /etc/modprobe.d                              │
# │ 2. ajoute "non-free" aux lignes Debian de sources.list (idempotent)   │
# │ 3. apt update + packages/80-nvidia.list (simulation : ARRÊT si        │
# │    suppression ou changement de version)                              │
# │ 4. vérifie DKMS, la mise en liste noire de nouveau, active            │
# │    nvidia-drm modeset=1 via /etc/modprobe.d (pas de GRUB), initramfs  │
# │ Redémarrage nécessaire ensuite. Retour arrière : nvidia-rollback-root.sh│
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,11p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
DRY=0
case ${1:-} in -h|--help) usage; exit 0 ;; --dry-run) DRY=1 ;; "") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
ts=$(date +%Y%m%d-%H%M%S); bk=/var/backups/setup-sway/$ts-nvidia
log() { printf '[nvidia] %s\n' "$*"; }

[[ $(mokutil --sb-state 2>/dev/null || true) == *enabled* ]] && log "⚠ Secure Boot ACTIF : il faudra enrôler la clé DKMS (mokutil --import /var/lib/dkms/mok.pub)"

if (( DRY )); then log "(dry-run) sauvegarde → $bk ; ajout non-free ; installation simulée seulement"
else
  install -d -m 700 "$bk"
  tar -czpf "$bk/etc-apt-modprobe.tar.gz" -C / etc/apt etc/modprobe.d
  log "sauvegarde : $bk"
fi

src=/etc/apt/sources.list
if grep -qE '^deb .*debian.* non-free( |$)' "$src"; then
  log "non-free déjà présent"
elif (( DRY )); then
  log "(dry-run) ajouterait non-free dans $src"
else
  sed -i -E '/^deb(-src)? .*debian/ s/ contrib( |$)/ contrib non-free\1/' "$src"
  log "non-free ajouté :"; grep -E '^deb ' "$src" | sed 's/^/    /'
fi

if (( DRY )); then exit 0; fi
apt-get update -qq
DEBIAN_FRONTEND=noninteractive "$here/apt-install.sh" "$here/packages/80-nvidia.list"

# Debian nomme le module « nvidia-current » (alias « nvidia » via modprobe.d)
log "DKMS :"; dkms status 2>&1 | sed 's/^/    /'
if modinfo -k "$(uname -r)" nvidia-current >/dev/null 2>&1 || modinfo -k "$(uname -r)" nvidia >/dev/null 2>&1; then log "✔ module nvidia construit pour $(uname -r)"
else log "✖ module nvidia absent pour $(uname -r)"; exit 4; fi
grep -RlsE '^\s*blacklist\s+nouveau' /etc/modprobe.d /usr/lib/modprobe.d | sed 's/^/    nouveau en liste noire : /' || log "⚠ nouveau non blacklisté"

if grep -RqsE 'nvidia[-_]drm.*modeset=1' /etc/modprobe.d /usr/lib/modprobe.d; then
  log "✔ nvidia-drm modeset=1 déjà fourni par le paquet"
else
  printf '# setup-sway : KMS NVIDIA (nécessaire à wlroots pour les sorties HDMI/DP de la dGPU)\noptions nvidia-drm modeset=1 fbdev=1\n' \
    > /etc/modprobe.d/nvidia-drm-setup-sway.conf
  log "✔ /etc/modprobe.d/nvidia-drm-setup-sway.conf créé (modeset=1 fbdev=1)"
fi
update-initramfs -u -k "$(uname -r)"
log "terminé : REDÉMARRER pour charger le pilote (nouveau est encore en mémoire)."

#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ rollback.sh — retour à l'état système initial (par morceaux)         │
# │ Usage : ./rollback.sh <commande> [--apply] [-h]                      │
# │   status    état : sauvegardes, paquets ajoutés, réseau               │
# │   user      = ./uninstall.sh (configuration utilisateur)              │
# │   network   rend wlo1 à ifupdown (system/network-rollback-root.sh)    │
# │   sources   restaure /etc/apt depuis /var/backups/setup-sway (tar)    │
# │   nvidia    retire le pilote NVIDIA (simulation ; --apply exécute)    │
# │   packages  liste les paquets marqués « manuels » depuis l'état       │
# │             initial et SIMULE leur purge ; --apply pour exécuter      │
# │             (après lecture de la simulation, aucune suppression       │
# │             forcée ; refus si sway/systemd/linux/grub seraient visés) │
# │ État initial : ~/.local/state/setup-sway/baseline-*/                  │
# │ Sauvegardes root : /var/backups/setup-sway/                           │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
DOT=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
# shellcheck source=scripts/.local/lib/soc/ui.sh
source "$DOT/scripts/.local/lib/soc/ui.sh"
usage() { sed -n '3,15p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }

cmd=${1:-status}; APPLY=0; [[ ${2:-} == --apply ]] && APPLY=1
BASE=$(find "$HOME/.local/state/setup-sway" -maxdepth 1 -type d -name 'baseline-*' 2>/dev/null | sort | head -1)
as_root() {
  if [[ -t 0 ]]; then sudo "$@"
  else SUDO_ASKPASS=$DOT/scripts/.local/bin/sudo-askpass sudo -A "$@"; fi
}
# added : paquets manuels ajoutés depuis l'état initial
added() { comm -13 <(sort "$BASE/apt-showmanual.txt") <(apt-mark showmanual | sort); }

case $cmd in
  -h|--help) usage ;;
  status)
    box_title "rollback · état" "référence : ${BASE:-AUCUNE}"
    section "Paquets ajoutés (manuels)"; [[ -n $BASE ]] && added | column -c 100 | sed 's/^/  /'
    section "Sauvegardes root"; as_root ls -1 /var/backups/setup-sway 2>/dev/null | sed 's/^/  /' || true
    section "Réseau"; nmcli -t -f DEVICE,STATE,CONNECTION device 2>/dev/null | sed 's/^/  /' || true ;;
  user) exec "$DOT/uninstall.sh" ;;
  network) as_root "$DOT/system/network-rollback-root.sh" ;;
  nvidia) as_root "$DOT/system/nvidia-rollback-root.sh" ${2:+"$2"} ;;
  sources)
    tarball=$(as_root find /var/backups/setup-sway -maxdepth 2 -name 'etc-apt-network.tar.gz' | sort | head -1)
    [[ -n $tarball ]] || die "aucune sauvegarde /etc/apt"
    info "restauration de /etc/apt/sources.list depuis $tarball"
    as_root tar -xzpf "$tarball" -C / etc/apt/sources.list
    as_root apt-get update
    ok "sources.list restauré" ;;
  packages)
    [[ -n $BASE ]] || die "état initial introuvable"
    # network-manager exclu : d'abord `./rollback.sh network`, puis purge manuelle
    mapfile -t pk < <(added | grep -vx network-manager)
    (( ${#pk[@]} )) || { ok "aucun paquet ajouté"; exit 0; }
    info "${#pk[@]} paquet(s) ajouté(s) depuis $(basename "$BASE")"
    sim=$(apt-get -s purge "${pk[@]}")
    grep -E '^Purg|^Remv' <<<"$sim" | sed 's/^/  /'
    if grep -E '^(Purg|Remv) ' <<<"$sim" | grep -qE ' (sway|systemd|linux-image|grub|ifupdown|sudo|network-manager|wpasupplicant)[ :]'; then
      die "la purge toucherait un paquet critique : ARRÊT (à arbitrer manuellement)"
    fi
    if (( APPLY )); then
      as_root apt-get purge "${pk[@]}"
    else
      warn "simulation seulement. Relancer avec --apply pour exécuter."
    fi ;;
  *) usage >&2; exit 1 ;;
esac

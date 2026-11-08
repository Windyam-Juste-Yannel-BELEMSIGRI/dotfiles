#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase-root.sh — installe une ou plusieurs listes de paquets et       │
# │ applique les réglages système associés (idempotent).                 │
# │ Usage : sudo phase-root.sh [--dry-run] LISTE.list [LISTE.list…]       │
# │ Réglages par liste :                                                  │
# │   30-audio-power : vérifie que tlp est absent (conflit PPD) et que    │
# │                    power-profiles-daemon est actif                    │
# │   70-soc-tools   : ajoute l'utilisateur appelant (SUDO_USER) au       │
# │                    groupe systemd-journal (lecture des journaux)      │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,10p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
DRY=0; lists=()
for a in "$@"; do case $a in -h|--help) usage; exit 0 ;; --dry-run) DRY=1 ;; *) lists+=("$a") ;; esac; done
(( ${#lists[@]} )) || { usage >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
dry=(); (( DRY )) && dry=(--dry-run)

"$here/apt-install.sh" "${dry[@]}" "${lists[@]}"
(( DRY )) && exit 0

for l in "${lists[@]}"; do
  case $(basename "$l") in
    30-audio-power.list)
      if dpkg -s tlp >/dev/null 2>&1; then echo "⚠ tlp installé : conflit avec power-profiles-daemon (non modifié, à arbitrer)"; fi
      if systemctl is-active --quiet power-profiles-daemon; then echo "✔ power-profiles-daemon actif"
      else systemctl enable --now power-profiles-daemon && echo "✔ power-profiles-daemon activé"; fi ;;
    70-soc-tools.list)
      u=${SUDO_USER:-}
      if [[ -n $u ]] && ! grep -qx systemd-journal <<<"$(id -nG "$u" | tr ' ' '\n')"; then
        usermod -aG systemd-journal "$u" && echo "✔ $u ajouté au groupe systemd-journal (effectif à la prochaine connexion)"
      fi ;;
  esac
done

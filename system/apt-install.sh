#!/usr/bin/env bash
# apt-install.sh — installe des listes de paquets Debian de façon sûre.
#   * simule d'abord (apt-get -s) et REFUSE si un paquet serait supprimé,
#     mis à niveau ou rétrogradé (aucune modif involontaire du système) ;
#   * installe avec --no-install-recommends ; idempotent.
# Usage : sudo apt-install.sh [--dry-run] fichier.list [fichier.list...]
set -euo pipefail

usage() { sed -n '2,7p' "$0"; }
DRY=0
lists=()
for a in "$@"; do
  case "$a" in
    -h|--help) usage; exit 0 ;;
    --dry-run) DRY=1 ;;
    *) lists+=("$a") ;;
  esac
done
(( ${#lists[@]} )) || { usage; exit 1; }

# read_list FILE : paquets d'une liste (commentaires et lignes vides ignorés)
read_list() { grep -vE '^\s*(#|$)' "$1" | awk '{print $1}'; }

pkgs=()
for l in "${lists[@]}"; do mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$l"); done
echo "▶ paquets demandés (${#pkgs[@]}) : ${pkgs[*]}"

sim=$(apt-get -s install --no-install-recommends "${pkgs[@]}")
if grep -qE '^(Remv|Purg) ' <<<"$sim"; then
  echo "✖ La simulation SUPPRIMERAIT des paquets — arrêt :" >&2
  grep -E '^(Remv|Purg) ' <<<"$sim" >&2; exit 2
fi
if grep -qE '^Inst [^ ]+ \[' <<<"$sim"; then
  echo "✖ La simulation modifierait la version de paquets existants — arrêt :" >&2
  grep -E '^Inst [^ ]+ \[' <<<"$sim" >&2; exit 3
fi
grep -E 'upgraded|newly' <<<"$sim" || true

if (( DRY )); then echo "(dry-run) rien installé"; exit 0; fi
[[ $EUID -eq 0 ]] || { echo "doit être lancé en root" >&2; exit 1; }
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${pkgs[@]}"
echo "▶ versions installées :"
dpkg-query -W -f='  ${Package}\t${Version}\n' "${pkgs[@]}"

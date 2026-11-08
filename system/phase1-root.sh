#!/usr/bin/env bash
# phase1-root.sh — actions root de la phase 1 :
#   1. sauvegarde /etc/apt /etc/network /etc/NetworkManager -> /var/backups/setup-sway/<ts>
#   2. ajoute "contrib" aux lignes Debian de /etc/apt/sources.list (idempotent)
#   3. apt-get update, puis installe system/packages/10-base.list
# Usage : sudo phase1-root.sh [--dry-run]
set -euo pipefail
DRY=0; [[ "${1:-}" == "--dry-run" ]] && DRY=1
[[ "${1:-}" == "-h" ]] && { sed -n '2,7p' "$0"; exit 0; }
here=$(cd "$(dirname "$0")" && pwd)
ts=$(date +%Y%m%d-%H%M%S)
bk=/var/backups/setup-sway/$ts

if (( DRY )); then
  echo "(dry-run) sauvegarderait /etc/apt /etc/network /etc/NetworkManager dans $bk"
else
  install -d -m 700 "$bk"
  dirs=(etc/apt etc/network); [[ -d /etc/NetworkManager ]] && dirs+=(etc/NetworkManager)
  tar -czpf "$bk/etc-apt-network.tar.gz" -C / "${dirs[@]}"
  echo "✔ sauvegarde : $bk/etc-apt-network.tar.gz"
fi

src=/etc/apt/sources.list
if grep -qE '^deb(-src)? .*debian.* main( |$)' "$src" && ! grep -qE '^deb .* main.*contrib' "$src"; then
  if (( DRY )); then echo "(dry-run) ajouterait contrib dans $src"
  else
    sed -i -E '/^deb(-src)? .*debian/ s/ main( |$)/ main contrib\1/' "$src"
    echo "✔ contrib ajouté :"; grep -E '^deb' "$src"
  fi
else
  echo "✔ contrib déjà présent (ou format inattendu, inchangé)"
fi

(( DRY )) || apt-get update
dry=(); (( DRY )) && dry=(--dry-run)
"$here/apt-install.sh" "${dry[@]}" "$here/packages/10-base.list"

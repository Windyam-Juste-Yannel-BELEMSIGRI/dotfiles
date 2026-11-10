#!/usr/bin/env bash
# Usage: install.sh <dossier-profil> <main|coursera>   (fermer le profil avant)
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd); p=${1:?profil}; kind=${2:?main|coursera}
[ -L "$p/lock" ] && { echo "Profil ouvert : ferme-le d'abord"; exit 1; }
mkdir -p "$p/chrome"
cp "$here/user.js" "$p/user.js"
python3 "$here/build.py"; cp "$here/userChrome-$kind.css" "$p/chrome/userChrome.css"; cp "$here/userContent-$kind.css" "$p/chrome/userContent.css"
cp "$here/bookmarks-$kind.html" "$p/bookmarks.html"

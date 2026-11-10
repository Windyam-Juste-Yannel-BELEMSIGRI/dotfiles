#!/usr/bin/env bash
# Installe qutebrowser « glass // SOC » : profils yannel + coursera, lanceur qb, entrées de menu.
# Idempotent. Prérequis : sudo apt install qutebrowser
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/.local/bin ~/.local/share/applications
for p in yannel coursera; do
  mkdir -p ~/.local/share/qb/$p/config
  ln -sf "$here/config.py" ~/.local/share/qb/$p/config/config.py
  { printf '[Desktop Entry]\nType=Application\nName=qutebrowser (%s)\nExec=%s/.local/bin/qb %s %%u\nIcon=qutebrowser\nCategories=Network;WebBrowser;\nStartupWMClass=qutebrowser\n' "$p" "$HOME" "$p"
    [ "$p" = yannel ] && echo 'MimeType=text/html;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;'
  } > ~/.local/share/applications/qb-$p.desktop
done
ln -sf "$here/qb" ~/.local/bin/qb
update-desktop-database ~/.local/share/applications 2>/dev/null || true
echo "OK. Lancer : qb   |   navigateur par défaut : xdg-settings set default-web-browser qb-yannel.desktop"
echo "Dans qutebrowser, une fois : :adblock-update"

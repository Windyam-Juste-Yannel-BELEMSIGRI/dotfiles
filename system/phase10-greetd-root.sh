#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase10-greetd-root.sh — écran de connexion greetd + tuigreet        │
# │ Usage : sudo phase10-greetd-root.sh [-h]                              │
# │ Installe greetd/tuigreet (thème glass // SOC, vt7, lance sway-launch) │
# │ sans démarrer greetd (effet au prochain démarrage). TTY 1-6 : invite  │
# │ Password: centrée (wrapper login), MOTD masqué, LOGIN_RETRIES=1.      │
# │ Annulation : rollback.sh boot                                         │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,8p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
case ${1:-} in -h|--help) usage; exit 0 ;; "") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
log() { printf '[greetd] %s\n' "$*"; }
src=$(cd "$(dirname "$0")" && pwd)/boot-theme

# apt ne doit pas démarrer greetd maintenant (couperait une session en cours)
printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod 755 /usr/sbin/policy-rc.d
trap 'rm -f /usr/sbin/policy-rc.d' EXIT
apt-get install -y greetd tuigreet

[[ -e /etc/greetd/config.toml.debian ]] || cp -a /etc/greetd/config.toml /etc/greetd/config.toml.debian
install -m 644 "$src/greetd/config.toml" /etc/greetd/config.toml
systemctl enable greetd.service
log "✔ greetd activé (vt7)"

# TTY de secours (Ctrl+Alt+F1…F6) : Password: sous login:, pas de MOTD
install -m 755 "$src/tty/login-centered" /usr/local/sbin/login-centered
install -d /etc/systemd/system/getty@.service.d
install -m 644 "$src/tty/getty-centered-login.conf" /etc/systemd/system/getty@.service.d/centered-login.conf
sed -i -E 's/^(\s*LOGIN_RETRIES\s+).*/\11/' /etc/login.defs
[[ -e /etc/pam.d/login.bak ]] || cp -a /etc/pam.d/login /etc/pam.d/login.bak
sed -i -E 's/^session\s+optional\s+pam_motd\.so/#&/' /etc/pam.d/login
systemctl daemon-reload
log "✔ TTY : wrapper login, LOGIN_RETRIES=1, MOTD masqué"
log "terminé : greetd au prochain démarrage."

#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ boot-theme-rollback-root.sh — retire le thème GRUB et le style TTY   │
# │ Usage : sudo boot-theme-rollback-root.sh [-h]                         │
# │ Supprime /etc/default/grub.d/90-glass-soc.cfg et                      │
# │ /boot/grub/themes/glass-soc, restaure /etc/default/console-setup      │
# │ (sauvegarde la plus ancienne) et /etc/issue, update-grub, initramfs.  │
# │ Utilisable depuis un TTY.                                             │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,8p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
case ${1:-} in -h|--help) usage; exit 0 ;; "") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
log() { printf '[boot-theme] %s\n' "$*"; }

rm -f /etc/default/grub.d/90-glass-soc.cfg
rm -rf /boot/grub/themes/glass-soc
tarball=$(find /var/backups/setup-sway -maxdepth 2 -path '*-boot-theme/etc-default.tar.gz' 2>/dev/null | sort | head -1)
if [[ -n $tarball ]]; then
  tar -xzpf "$tarball" -C / etc/default/console-setup
  log "console-setup restauré depuis $tarball"
else
  sed -i -E 's/^FONTFACE=.*/FONTFACE="Fixed"/; s/^FONTSIZE=.*/FONTSIZE="8x16"/' /etc/default/console-setup
  log "aucune sauvegarde : console-setup remis aux valeurs Debian (Fixed 8x16)"
fi
[[ -e /var/backups/setup-sway/issue.orig ]] && cp -a /var/backups/setup-sway/issue.orig /etc/issue && log "/etc/issue restauré"
# phase10 : greetd + TTY (Password: centré, MOTD masqué)
if systemctl is-enabled --quiet greetd.service 2>/dev/null; then
  systemctl disable greetd.service
  [[ -e /etc/greetd/config.toml.debian ]] && cp -a /etc/greetd/config.toml.debian /etc/greetd/config.toml
  log "greetd désactivé (connexion par agetty sur tty1 ; ajouter l'autostart Sway au besoin)"
fi
rm -f /usr/local/sbin/login-centered /etc/systemd/system/getty@.service.d/centered-login.conf
rmdir /etc/systemd/system/getty@.service.d 2>/dev/null || true
sed -i -E 's/^(\s*LOGIN_RETRIES\s+).*/\15/' /etc/login.defs
[[ -e /etc/pam.d/login.bak ]] && mv -f /etc/pam.d/login.bak /etc/pam.d/login && log "/etc/pam.d/login restauré"
systemctl daemon-reload
update-grub
systemctl restart console-setup.service || true
update-initramfs -u -k "$(uname -r)"
log "terminé : GRUB et TTY reviennent à l'apparence Debian au prochain démarrage."

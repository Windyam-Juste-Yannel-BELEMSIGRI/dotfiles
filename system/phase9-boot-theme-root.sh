#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase9-boot-theme-root.sh — GRUB + TTY aux couleurs « glass // SOC » │
# │ Usage : sudo phase9-boot-theme-root.sh [--dry-run] [-h]               │
# │ 1. sauvegarde /etc/default/{grub,grub.d,console-setup} + grub.cfg     │
# │ 2. thème → /boot/grub/themes/glass-soc (polices JetBrains Mono .pf2)  │
# │ 3. /etc/default/grub.d/90-glass-soc.cfg (thème, gfxterm, vt.default_*)│
# │    /etc/default/grub n'est PAS modifié                                │
# │ 4. grub.cfg généré à part + grub-script-check AVANT update-grub       │
# │ 5. console : Terminus Bold 16x32, palette appliquée (setvtrgb),       │
# │    /etc/issue centré (écran 160x50), initramfs régénéré               │
# │ Retour arrière : boot-theme-rollback-root.sh                          │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,12p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
DRY=0
case ${1:-} in -h|--help) usage; exit 0 ;; --dry-run) DRY=1 ;; "") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd); src=$here/boot-theme
ts=$(date +%Y%m%d-%H%M%S); bk=/var/backups/setup-sway/$ts-boot-theme
themedir=/boot/grub/themes/glass-soc
fontdir=/usr/share/fonts/truetype/jetbrains-mono
log() { printf '[boot-theme] %s\n' "$*"; }

for f in "$src/grub/glass-soc/theme.txt" "$src/grub.d/90-glass-soc.cfg" "$src/vt-palette.txt" "$src/issue" \
         "$fontdir/JetBrainsMono-Regular.ttf" "$fontdir/JetBrainsMono-Bold.ttf" \
         /usr/share/consolefonts/Lat15-TerminusBold32x16.psf.gz; do
  [[ -r $f ]] || { log "✖ manquant : $f"; exit 2; }
done
for c in grub-mkfont grub-mkconfig grub-script-check setvtrgb; do command -v "$c" >/dev/null || { log "✖ $c absent"; exit 2; }; done

if (( DRY )); then
  log "(dry-run) sauvegarde → $bk ; thème → $themedir ; /etc/default/grub.d/90-glass-soc.cfg ;"
  log "(dry-run) console-setup : FONTFACE=TerminusBold FONTSIZE=16x32 ; update-grub ; update-initramfs -u"
  exit 0
fi

# 1. sauvegardes
install -d -m 700 "$bk"
tar -czpf "$bk/etc-default.tar.gz" -C / etc/default/grub etc/default/grub.d etc/default/console-setup
cp -a /boot/grub/grub.cfg "$bk/grub.cfg.orig"
# /etc/issue d'origine : sauvegardé une seule fois (les passages suivants ne l'écrasent pas)
[[ -e /var/backups/setup-sway/issue.orig ]] || cp -a /etc/issue /var/backups/setup-sway/issue.orig
log "sauvegarde : $bk"

# 2. thème + polices (nom GRUB = « JetBrains Mono <Style> <taille> »)
install -d -m 755 "$themedir"
install -m 644 "$src"/grub/glass-soc/{theme.txt,*.png} "$themedir/"
range=0x20-0x17F,0x2010-0x2027,0x2190-0x21FF,0x2500-0x25FF
mk() { grub-mkfont -r "$range" -s "$2" -o "$themedir/jbm-$1-$2.pf2" "$fontdir/JetBrainsMono-$1.ttf" 2>/dev/null; }
mk Regular 24; mk Regular 32; mk Bold 32; mk Bold 48
log "thème installé : $(find "$themedir" -type f | wc -l) fichiers"

# 3. configuration GRUB (fichier dédié, /etc/default/grub intact)
install -D -m 644 "$src/grub.d/90-glass-soc.cfg" /etc/default/grub.d/90-glass-soc.cfg

# 4. génération vérifiée avant installation
tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
grub-mkconfig -o "$tmp" 2>&1 | sed 's/^/    /'
grub-script-check "$tmp" || { log "✖ grub.cfg invalide : ARRÊT, retrait du fichier de config"; rm -f /etc/default/grub.d/90-glass-soc.cfg; exit 3; }
grep -q 'set theme=' "$tmp" || { log "✖ thème non pris en compte : ARRÊT"; rm -f /etc/default/grub.d/90-glass-soc.cfg; exit 3; }
grep -q 'vt.default_red=' "$tmp" || { log "✖ palette absente de la ligne noyau : ARRÊT"; rm -f /etc/default/grub.d/90-glass-soc.cfg; exit 3; }
update-grub 2>&1 | sed 's/^/    /'
log "✔ grub.cfg : thème + vt.default_* ($(grep -c '^menuentry\|^submenu' /boot/grub/grub.cfg) entrées de premier niveau)"

# 5. console
cfg=/etc/default/console-setup
sed -i -E 's/^FONTFACE=.*/FONTFACE="TerminusBold"/; s/^FONTSIZE=.*/FONTSIZE="16x32"/' "$cfg"
grep -E '^(CODESET|FONTFACE|FONTSIZE)=' "$cfg" | sed 's/^/    /'
systemctl restart console-setup.service || log "⚠ console-setup non relancé (appliqué au prochain démarrage)"
if setvtrgb -C /dev/tty1 "$src/vt-palette.txt" 2>/dev/null; then log "✔ palette appliquée aux TTY ouverts"
else log "⚠ setvtrgb impossible (palette appliquée au prochain démarrage)"; fi
# écran de connexion centré (positions calculées pour 160x50 : Terminus 16x32 sur 2560x1600)
install -m 644 "$src/issue" /etc/issue
log "✔ /etc/issue centré installé"
update-initramfs -u -k "$(uname -r)" 2>&1 | sed 's/^/    /'
log "terminé : visible au prochain redémarrage (GRUB) ; Ctrl+Alt+F2 pour voir un TTY maintenant."

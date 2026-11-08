# ~/.bash_profile — shell de connexion (géré par ~/dotfiles/bash)
# Bash lit ce fichier À LA PLACE de ~/.profile : on le source donc d'abord.
# (Le ~/.profile Debian charge lui-même ~/.bashrc et ajoute ~/.local/bin.)
# shellcheck source=/dev/null
[ -r "$HOME/.profile" ] && . "$HOME/.profile"

# ── Démarrage automatique de Sway ─────────────────────────────────────────
# Conditions : TTY1 uniquement, pas de session graphique déjà lancée,
# pas de connexion SSH, et pas de fichier d'annulation.
#   Annuler (une fois / définitivement) : touch ~/.config/sway/no-autostart
#   Réactiver                            : rm ~/.config/sway/no-autostart
#   Démarrer en mode secours             : touch ~/.config/sway/use-fallback
# Si Sway quitte (ou plante), on revient à ce TTY avec un shell normal.
if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ] \
   && [ -z "${SSH_CONNECTION:-}${SSH_TTY:-}" ] \
   && [ "$(tty)" = "/dev/tty1" ] \
   && [ ! -e "$HOME/.config/sway/no-autostart" ] \
   && command -v sway >/dev/null 2>&1; then
  printf '\033[38;2;125;211;192m▶ démarrage de Sway (annuler : Ctrl+C dans 2 s)\033[0m\n'
  if sleep 2; then
    "$HOME/.local/bin/sway-launch"
    printf '\nSway terminé (code %s). Journal : ~/.local/state/sway/sway.log\n' "$?"
  fi
fi

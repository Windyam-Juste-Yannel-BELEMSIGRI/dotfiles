# ~/.bash_profile — shell de connexion (géré par ~/dotfiles/bash)
# Bash lit ce fichier À LA PLACE de ~/.profile : on le source donc d'abord.
# (Le ~/.profile Debian charge lui-même ~/.bashrc et ajoute ~/.local/bin.)
# shellcheck source=/dev/null
[ -r "$HOME/.profile" ] && . "$HOME/.profile"

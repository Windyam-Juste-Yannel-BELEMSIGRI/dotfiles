# ~/.config/bash/init.sh — chargé par ~/.bashrc (ligne ajoutée par install.sh)
# Charge chaque module NN-*.sh dans l'ordre, puis local.sh (non versionné).
case $- in *i*) ;; *) return ;; esac
for __f in "$HOME"/.config/bash/[0-9][0-9]-*.sh "$HOME"/.config/bash/local.sh; do
  # shellcheck disable=SC1090
  [ -r "$__f" ] && . "$__f"
done
unset __f

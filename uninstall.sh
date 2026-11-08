#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ uninstall.sh — retire la configuration utilisateur "glass // SOC"    │
# │ Usage : ./uninstall.sh [--dry-run] [--keep-fonts] [-h]               │
# │  1. arrête sway-session.target (services user)                        │
# │  2. supprime les liens stow (seuls les liens pointant vers ~/dotfiles)│
# │  3. retire le hook de ~/.bashrc                                       │
# │  4. restaure la sauvegarde la plus récente ~/.config-backup-*/        │
# │  5. supprime la police Nerd Font (sauf --keep-fonts)                  │
# │ Ne touche PAS au système (apt, réseau) : voir ./rollback.sh.          │
# │ Sway reste utilisable : sans ~/.config/sway, il charge /etc/sway/config│
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
DOT=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
# shellcheck source=scripts/.local/lib/soc/ui.sh
source "$DOT/scripts/.local/lib/soc/ui.sh"
usage() { sed -n '3,11p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }

DRY=0 KEEPF=0
for a in "$@"; do
  case $a in --dry-run) DRY=1 ;; --keep-fonts) KEEPF=1 ;; -h|--help) usage; exit 0 ;; *) usage >&2; exit 1 ;; esac
done
run() { if (( DRY )); then printf '  (dry-run) %s\n' "$*"; else "$@"; fi; }

STOW_PKGS=(sway waybar foot fuzzel mako swaylock swayidle kanshi swappy cava
           systemd-user scripts soc gtk bash starship tmux nvim)

box_title "uninstall.sh" "$( (( DRY )) && echo 'dry-run : aucune modification' || echo 'retrait de la configuration utilisateur')"

section "1. SERVICES"
run systemctl --user stop sway-session.target 2>/dev/null || true

section "2. LIENS STOW"
need stow
sflags=(-D -d "$DOT" -t "$HOME"); (( DRY )) && sflags+=(--simulate -v)
stow "${sflags[@]}" "${STOW_PKGS[@]}"
ok "liens retirés"

section "3. ~/.bashrc"
if grep -qF 'dotfiles glass-soc' "$HOME/.bashrc" 2>/dev/null; then
  run sed -i '/dotfiles glass-soc/d' "$HOME/.bashrc"; ok "hook retiré"
fi

section "4. RESTAURATION"
bk=$(find "$HOME" -maxdepth 1 -type d -name '.config-backup-*' | sort | tail -1)
if [[ -n $bk ]]; then
  info "sauvegarde : $bk"
  while IFS= read -r -d '' f; do
    rel=${f#"$bk/"}
    [[ $rel == .bashrc.orig ]] && continue
    if [[ ! -e $HOME/$rel ]]; then run mkdir -p "$(dirname "$HOME/$rel")"; run cp -a "$f" "$HOME/$rel"; ok "restauré : ~/$rel"; fi
  done < <(find "$bk" -type f -print0)
else
  info "aucune sauvegarde à restaurer"
fi

section "5. POLICE"
if (( ! KEEPF )) && [[ -d $HOME/.local/share/fonts/JetBrainsMonoNerdFont ]]; then
  run rm -r "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"; run fc-cache -f
fi
run systemctl --user daemon-reload
ok "configuration retirée. Paquets/réseau inchangés (./rollback.sh pour le système)."

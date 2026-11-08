#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ install.sh — déploie l'environnement Sway "glass // SOC"             │
# │ Cible : Debian 13 (trixie), dépôts officiels uniquement.              │
# │                                                                       │
# │ Usage : ./install.sh [options]                                        │
# │   --dry-run          n'écrit rien, affiche ce qui serait fait         │
# │   --no-packages      ne touche pas à apt (configuration seule)        │
# │   --with-soc-tools   installe aussi packages/70-soc-tools.list        │
# │   --migrate-network  migre wlo1 d'ifupdown vers NetworkManager        │
# │                      (garde-fou + retour auto, voir system/)          │
# │   -h, --help         cette aide                                       │
# │                                                                       │
# │ Étapes (idempotentes, relançables) :                                  │
# │  1. vérifications (Debian 13, sudo, Wayland)                          │
# │  2. apt : contrib + listes system/packages/{10,20,30,40,50}*.list     │
# │     (simulation préalable, ARRÊT si suppression/changement de version)│
# │  3. sauvegarde des fichiers existants → ~/.config-backup-AAAAMMJJ/    │
# │  4. liens symboliques GNU stow (--no-folding) vers $HOME              │
# │  5. hook ~/.bashrc, police Nerd Font (SHA-256 vérifié), fond d'écran  │
# │  6. systemd --user daemon-reload, validation `sway -C`                │
# │ Annulation : ./uninstall.sh (config) · ./rollback.sh (système)        │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
DOT=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
# shellcheck source=scripts/.local/lib/soc/ui.sh
source "$DOT/scripts/.local/lib/soc/ui.sh"
usage() { sed -n '3,24p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }

DRY=0 PKG=1 SOC=0 NET=0
for a in "$@"; do
  case $a in
    --dry-run) DRY=1 ;; --no-packages) PKG=0 ;; --with-soc-tools) SOC=1 ;;
    --migrate-network) NET=1 ;; -h|--help) usage; exit 0 ;;
    *) err "option inconnue : $a"; usage >&2; exit 1 ;;
  esac
done

STOW_PKGS=(sway waybar foot fuzzel mako swaylock swayidle kanshi swappy cava
           systemd-user scripts soc gtk bash starship tmux nvim)
NF_VERSION=v3.5.1
NF_URL=https://github.com/ryanoasis/nerd-fonts/releases/download/$NF_VERSION
BACKUP=$HOME/.config-backup-$(date +%Y%m%d)
LOG=${XDG_STATE_HOME:-$HOME/.local/state}/setup-sway/journal.md

# run CMD… : exécute (ou affiche en --dry-run)
run() { if (( DRY )); then printf '  %s(dry-run)%s %s\n' "$C_MUTED" "$C_RST" "$*"; else "$@"; fi; }
# journal TEXTE : ajoute une ligne au journal d'installation
journal() { (( DRY )) || { mkdir -p "${LOG%/*}"; printf -- '- %s — %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }; }
# as_root CMD… : sudo, avec helper graphique si pas de TTY
as_root() {
  if [[ -t 0 ]]; then sudo "$@"
  else SUDO_ASKPASS=$DOT/scripts/.local/bin/sudo-askpass sudo -A "$@"; fi
}

banner "install.sh · $(date '+%F %T')"
(( DRY )) && warn "mode --dry-run : aucune modification"

# ── 1. Vérifications ────────────────────────────────────────────────────
section "1. VÉRIFICATIONS"
. /etc/os-release
[[ ${VERSION_CODENAME:-} == trixie ]] || die "Debian 13 (trixie) requis (trouvé : ${PRETTY_NAME:-?})"
ok "$PRETTY_NAME"
[[ $EUID -ne 0 ]] || die "à lancer en utilisateur normal (sudo sera demandé si besoin)"
command -v sudo >/dev/null || die "sudo requis"

# ── 2. Paquets ──────────────────────────────────────────────────────────
section "2. PAQUETS (apt, dépôts officiels)"
if (( PKG )); then
  lists=("$DOT"/system/packages/{10,30,40,50}-*.list)
  (( SOC )) && lists+=("$DOT"/system/packages/70-soc-tools.list)
  if (( DRY )); then
    "$DOT/system/apt-install.sh" --dry-run "${lists[@]}" | tail -3
  else
    as_root "$DOT/system/phase1-root.sh"               # contrib + base (10)
    as_root "$DOT/system/phase-root.sh" "${lists[@]:1}" # 30/40/50(/70)
    journal "install.sh : paquets installés (${lists[*]##*/})"
  fi
  if (( NET )); then
    if (( DRY )); then as_root "$DOT/system/phase2-network-root.sh" --dry-run
    else as_root "$DOT/system/phase2-network-root.sh"; fi
  else
    info "réseau : --migrate-network non demandé (NetworkManager : $(systemctl is-active NetworkManager 2>/dev/null || echo absent))"
  fi
else
  info "--no-packages : apt ignoré"
fi
need stow

# ── 3. Sauvegarde des fichiers en conflit ───────────────────────────────
section "3. SAUVEGARDE → $BACKUP"
conflicts=0
for p in "${STOW_PKGS[@]}"; do
  while IFS= read -r -d '' f; do
    rel=${f#"$DOT/$p/"}; tgt=$HOME/$rel
    if [[ -e $tgt && ! -L $tgt ]]; then
      conflicts=$((conflicts + 1))
      run mkdir -p "$BACKUP/$(dirname "$rel")"
      run mv "$tgt" "$BACKUP/$rel"
      journal "sauvegarde : ~/$rel → $BACKUP/$rel"
    fi
  done < <(find "$DOT/$p" -type f -print0)
done
ok "$conflicts fichier(s) existant(s) sauvegardé(s)"

# ── 4. Liens stow ───────────────────────────────────────────────────────
section "4. LIENS (GNU stow --no-folding)"
mkdir -p "$HOME/.local/bin" "$HOME/.config"
sflags=(--no-folding --restow -d "$DOT" -t "$HOME")
(( DRY )) && sflags+=(--simulate -v)
if ! stow "${sflags[@]}" "${STOW_PKGS[@]}"; then
  (( DRY )) || die "stow a échoué"
  warn "(dry-run) conflits attendus : ces fichiers seraient d'abord sauvegardés (étape 3)"
fi
ok "paquets stow : ${STOW_PKGS[*]}"
journal "stow : ${STOW_PKGS[*]}"

# ── 5. Hook bashrc, police, fond d'écran ───────────────────────────────
section "5. SHELL / POLICE / FOND"
# shellcheck disable=SC2016  # $HOME doit rester littéral dans ~/.bashrc
HOOK='[ -r "$HOME/.config/bash/init.sh" ] && . "$HOME/.config/bash/init.sh"  # dotfiles glass-soc'
if ! grep -qF 'dotfiles glass-soc' "$HOME/.bashrc" 2>/dev/null; then
  if (( ! DRY )); then
    mkdir -p "$BACKUP"; cp -a "$HOME/.bashrc" "$BACKUP/.bashrc.orig" 2>/dev/null || true
    printf '\n%s\n' "$HOOK" >> "$HOME/.bashrc"
    journal "\$HOME/.bashrc : ajout du hook init.sh (original : $BACKUP/.bashrc.orig)"
  fi
  ok "hook ajouté à ~/.bashrc"
else
  ok "hook ~/.bashrc déjà présent"
fi

FONT_DIR=$HOME/.local/share/fonts/JetBrainsMonoNerdFont
if [[ -n $(fc-list 'JetBrainsMono Nerd Font') ]]; then
  ok "JetBrainsMono Nerd Font déjà installée"
elif (( DRY )); then
  info "(dry-run) téléchargerait JetBrainsMono.tar.xz $NF_VERSION + vérification SHA-256"
else
  tmp=$(mktemp -d)
  curl -fsSL -o "$tmp/JetBrainsMono.tar.xz" "$NF_URL/JetBrainsMono.tar.xz"
  curl -fsSL -o "$tmp/SHA-256.txt" "$NF_URL/SHA-256.txt"
  (cd "$tmp" && grep ' JetBrainsMono.tar.xz$' SHA-256.txt | sha256sum -c -) || die "SHA-256 invalide : police rejetée"
  mkdir -p "$FONT_DIR"; tar -xJf "$tmp/JetBrainsMono.tar.xz" -C "$FONT_DIR" --wildcards '*.ttf'
  rm -rf "$tmp"; fc-cache -f "$FONT_DIR" >/dev/null
  ok "Nerd Font installée ($NF_VERSION, SHA-256 vérifié)"
  journal "police JetBrainsMono Nerd Font $NF_VERSION → $FONT_DIR (SHA-256 vérifié)"
fi
mkdir -p "$HOME/Pictures/wallpaper" "$HOME/Pictures/Screenshots" "$HOME/Videos/Recordings"
if [[ ! -e $HOME/.local/share/backgrounds/current ]]; then
  run "$HOME/.local/bin/set-wallpaper" apply
fi

# ── 6. systemd --user et validation ────────────────────────────────────
section "6. VALIDATION"
run systemctl --user daemon-reload
if sway -C -c "$HOME/.config/sway/config" >/dev/null 2>&1; then ok "sway -C : configuration valide"
elif (( DRY )); then warn "sway -C : non vérifiable en dry-run avant liens"
else die "sway -C : configuration INVALIDE (voir sway -C)"; fi
if command -v shellcheck >/dev/null; then
  if (cd "$DOT" && shellcheck -x scripts/.local/bin/* scripts/.local/lib/soc/ui.sh system/*.sh ./*.sh); then
    ok "shellcheck : 0 avertissement"
  else warn "shellcheck : avertissements ci-dessus"; fi
fi
if [[ -n ${SWAYSOCK:-} ]] && (( ! DRY )); then
  swaymsg reload >/dev/null && ok "sway rechargé"
  systemctl --user restart sway-session.target && ok "services de session (re)démarrés"
else
  info "Sway non lancé : connectez-vous sur tty1 (démarrage automatique)"
fi
ok "terminé. Documentation : $DOT/docs/RAPPORT.md"

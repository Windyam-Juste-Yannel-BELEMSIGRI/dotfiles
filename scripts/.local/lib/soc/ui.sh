#!/usr/bin/env bash
# shellcheck shell=bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ ui.sh — bibliothèque commune "glass // SOC" pour ~/.local/bin/*       │
# │ Couleurs ANSI (palette du thème), boîtes Unicode, bannières, barres  │
# │ de progression, spinner, vérification des dépendances, menus fuzzel. │
# │ Usage : source "$(dirname "$(readlink -f "$0")")/../lib/soc/ui.sh"    │
# ╰──────────────────────────────────────────────────────────────────────╯

# Garde contre le double chargement
[[ -n "${__SOC_UI_LOADED:-}" ]] && return 0
__SOC_UI_LOADED=1

# Outils d'administration en lecture (rfkill, iw, ss…) : /usr/sbin hors PATH
# utilisateur par défaut sous Debian.
case ":$PATH:" in *:/usr/sbin:*) ;; *) PATH=$PATH:/usr/sbin:/sbin ;; esac

# ── Couleurs (désactivées si stdout n'est pas un terminal ou NO_COLOR) ──
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RST=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
  C_ACC=$'\e[38;2;0;255;156m'    # #00ff9c vert « matrix » (accent)
  C_ACC2=$'\e[38;2;0;229;255m'   # #00e5ff cyan (réseau)
  C_FG=$'\e[38;2;197;209;222m'     # #c5d1de
  C_MUTED=$'\e[38;2;125;136;152m'  # #7d8898
  C_RED=$'\e[38;2;255;83;112m'    # #ff5370
  C_GRN=$'\e[38;2;0;255;156m'    # #00ff9c
  C_YEL=$'\e[38;2;255;176;0m'     # #ffb000
  C_BLU=$'\e[38;2;79;195;247m'    # #4fc3f7
  C_MAG=$'\e[38;2;179;136;255m'    # #b388ff
else
  C_RST=; C_BOLD=; C_DIM=; C_ACC=; C_ACC2=; C_FG=; C_MUTED=
  C_RED=; C_GRN=; C_YEL=; C_BLU=; C_MAG=
fi
export C_RST C_BOLD C_DIM C_ACC C_ACC2 C_FG C_MUTED C_RED C_GRN C_YEL C_BLU C_MAG

# ── Messages ────────────────────────────────────────────────────────────
# info/ok/warn/err MESSAGE : ligne préfixée et colorée (err → stderr)
info() { printf '%s[·]%s %s\n' "$C_ACC" "$C_RST" "$*"; }
ok()   { printf '%s[✔]%s %s\n' "$C_GRN" "$C_RST" "$*"; }
warn() { printf '%s[!]%s %s\n' "$C_YEL" "$C_RST" "$*" >&2; }
err()  { printf '%s[✖]%s %s\n' "$C_RED" "$C_RST" "$*" >&2; }
# die MESSAGE : erreur puis sortie code 1
die()  { err "$*"; exit 1; }

# need CMD... : vérifie que chaque commande existe, sinon quitte avec la
# liste des manquantes et le paquet Debian probable.
need() {
  local missing=() c
  for c in "$@"; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
  if (( ${#missing[@]} )); then
    err "dépendance(s) manquante(s) : ${missing[*]}"
    err "→ sudo apt install <paquet> (voir ~/dotfiles/system/packages/)"
    exit 127
  fi
}

# notify TITRE [CORPS] [options notify-send...] : notification si possible
notify() {
  local title=$1; shift
  local body=${1:-}; (( $# )) && shift
  if command -v notify-send >/dev/null; then
    notify-send -a soc "$title" "$body" "$@" || true
  fi
}

# ── Boîtes / bannières ──────────────────────────────────────────────────
# term_width : largeur du terminal (80 par défaut)
term_width() { local w; w=$(tput cols 2>/dev/null || echo 80); echo "${w:-80}"; }

# hr [CAR] : ligne horizontale pleine largeur
hr() { local w; w=$(term_width); printf '%s%*s%s\n' "$C_DIM" "$w" '' "$C_RST" | tr ' ' "${1:-─}"; }

# box_title TITRE [SOUS-TITRE] : en-tête encadré façon "rapport"
box_title() {
  local t=$1 s=${2:-} w; w=$(( $(term_width) - 2 ))
  (( w > 78 )) && w=78
  printf '%s╭%s╮%s\n' "$C_ACC" "$(printf '─%.0s' $(seq 1 "$w"))" "$C_RST"
  # remplissage calculé en caractères (${#x}) et non en octets (printf %-*s)
  printf '%s│%s %s%s%*s%s%s│%s\n' "$C_ACC" "$C_RST" "$C_BOLD$C_FG" "$t" $((w - 1 - ${#t})) '' "$C_RST" "$C_ACC" "$C_RST"
  [[ -n "$s" ]] && printf '%s│%s %s%s%*s%s%s│%s\n' "$C_ACC" "$C_RST" "$C_MUTED" "$s" $((w - 1 - ${#s})) '' "$C_RST" "$C_ACC" "$C_RST"
  printf '%s╰%s╯%s\n' "$C_ACC" "$(printf '─%.0s' $(seq 1 "$w"))" "$C_RST"
}

# section TITRE : intertitre "── TITRE ─────"
section() {
  local t=" $1 " w; w=$(( $(term_width) - ${#t} - 3 )); (( w < 3 )) && w=3
  printf '\n%s──%s%s%s%s\n' "$C_ACC" "$C_BOLD$C_FG" "$t" "$C_RST$C_DIM" "$(printf '─%.0s' $(seq 1 "$w"))$C_RST"
}

# banner [SOUS-TITRE] : logo "SOC // GLASS" (3 lignes) + sous-titre
banner() {
  printf '%s' "$C_ACC"
  cat <<'B'
  ┌─┐┌─┐┌─┐   ╱╱   ┌─┐┬  ┌─┐┌─┐┌─┐
  └─┐│ ││    ╱╱    │ ┬│  ├─┤└─┐└─┐
  └─┘└─┘└─┘ ╱╱     └─┘┴─┘┴ ┴└─┘└─┘
B
  printf '%s' "$C_RST"
  [[ -n "${1:-}" ]] && printf '  %s%s%s
' "$C_MUTED" "$1" "$C_RST"
  return 0
}

# ── Jauges ──────────────────────────────────────────────────────────────
# color_for PCT [WARN=70] [CRIT=90] : code couleur selon un seuil
color_for() {
  local p=${1%.*} w=${2:-70} c=${3:-90}
  if (( p >= c )); then printf '%s' "$C_RED"
  elif (( p >= w )); then printf '%s' "$C_YEL"
  else printf '%s' "$C_GRN"; fi
}

# bar PCT [LARGEUR=24] : barre de progression ▰▱ colorée selon le seuil
bar() {
  local p=${1%.*} n=${2:-24} f i out=
  (( p < 0 )) && p=0; (( p > 100 )) && p=100
  f=$(( p * n / 100 ))
  for (( i = 0; i < n; i++ )); do
    if (( i < f )); then out+='▰'; else out+='▱'; fi
  done
  printf '%s%s%s %3d%%' "$(color_for "$p")" "$out" "$C_RST" "$p"
}

# spinner PID [MESSAGE] : anime un spinner tant que PID tourne
spinner() {
  local pid=$1 msg=${2:-travail en cours} frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  [[ -t 1 ]] || { wait "$pid"; return; }
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r%s%s%s %s' "$C_ACC" "${frames:i++%${#frames}:1}" "$C_RST" "$msg"
    sleep 0.08
  done
  printf '\r\e[K'
  wait "$pid"
}

# human BYTES : taille lisible (Ki/Mi/Gi)
human() { numfmt --to=iec-i --suffix=B "${1:-0}" 2>/dev/null || echo "${1}B"; }

# ── Menus (fuzzel en mode dmenu) ───────────────────────────────────────
# menu PROMPT [options fuzzel...] : lit les entrées sur stdin, renvoie le choix
#   Si un fuzzel est déjà ouvert (re-clic sur un bouton waybar), on le ferme
#   et on s'arrête : le bouton agit comme un interrupteur.
menu() {
  local prompt=$1; shift
  if pgrep -x fuzzel >/dev/null; then pkill -x fuzzel; exit 0; fi
  fuzzel --dmenu --prompt "$prompt " --lines 12 --width 48 "$@"
}

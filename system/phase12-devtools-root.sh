#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase12-devtools-root.sh — outils de travail (partie root)           │
# │ Usage : sudo phase12-devtools-root.sh [--dry-run] [-h]               │
# │  1. dépôt VS Code via extrepo (définition + clé maintenues par       │
# │     Debian), épinglé : seul le paquet `code` peut en venir ;         │
# │  2. lot packages/90-dev.list (simulation, 0 suppression/version) ;   │
# │  3. Wireshark : capture sans root via le groupe wireshark ;          │
# │  4. Docker : démarrage à la demande (socket), ports publiés sur      │
# │     127.0.0.1 par défaut, logs plafonnés ; groupe docker.            │
# │ Partie utilisateur ensuite : dev-setup (uv, Node via fnm, VS Code).  │
# │ Annulation : sudo devtools-rollback-root.sh                          │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,13p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
DRY=0
case ${1:-} in -h|--help) usage; exit 0 ;; --dry-run) DRY=1 ;; "") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
log() { printf '[dev] %s\n' "$*"; }
here=$(cd "$(dirname "$0")" && pwd)
USR=${SUDO_USER:?lancer via sudo depuis ton compte}
STAMP=/var/backups/glass-soc/phase12-$(date +%Y%m%d-%H%M%S)

# --dry-run : simulation seule (sans `code`, dont le dépôt n'existe pas encore)
if (( DRY )); then
  tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
  grep -v '^code$' "$here/packages/90-dev.list" > "$tmp"
  "$here/apt-install.sh" --dry-run "$tmp"
  log "(dry-run) + extrepo, dépôt vscode, code — rien n'a été modifié"; exit 0
fi

# ── 1. Dépôt VS Code (extrepo) ──────────────────────────────────────────
if [[ ! -e /etc/apt/sources.list.d/extrepo_vscode.sources ]]; then
  mkdir -p "$STAMP"; cp -a /etc/apt "$STAMP/"
  log "sauvegarde /etc/apt → $STAMP"
  apt-get install -y --no-install-recommends extrepo
  # politique non-free (licence Microsoft) autorisée pour extrepo
  sed -i 's/^# *- non-free$/- non-free/' /etc/extrepo/config.yaml
  grep -q '^- non-free$' /etc/extrepo/config.yaml || printf -- '- non-free\n' >> /etc/extrepo/config.yaml
  extrepo enable vscode
fi
# Épinglage : rien d'autre que `code` ne peut venir de packages.microsoft.com
cat > /etc/apt/preferences.d/vscode.pref <<'EOF'
# glass-soc phase 12 : seul `code` est accepté depuis le dépôt Microsoft
Package: *
Pin: origin "packages.microsoft.com"
Pin-Priority: -1

Package: code
Pin: origin "packages.microsoft.com"
Pin-Priority: 500
EOF
apt-get update -q

# ── 2. Paquets ──────────────────────────────────────────────────────────
# Wireshark : dumpcap setuid restreint au groupe wireshark (question debconf)
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
"$here/apt-install.sh" "$here/packages/90-dev.list"

# ── 3. Groupes ──────────────────────────────────────────────────────────
usermod -aG wireshark,docker "$USR"
log "✔ $USR ajouté à wireshark et docker (effet à la prochaine connexion)"

# ── 4. Docker ───────────────────────────────────────────────────────────
install -d /etc/docker
if [[ ! -e /etc/docker/daemon.json ]]; then
  cat > /etc/docker/daemon.json <<'EOF'
{
  "ip": "127.0.0.1",
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
  log "✔ /etc/docker/daemon.json : ports publiés sur 127.0.0.1, logs 3×10 Mo"
fi
# Démarrage à la demande : rien ne tourne tant que `docker` n'est pas utilisé
systemctl disable --now docker.service containerd.service 2>/dev/null || true
systemctl enable --now docker.socket
log "✔ Docker : docker.socket actif, démon lancé à la première commande"

log "✔ terminé — puis, sans sudo : dev-setup"

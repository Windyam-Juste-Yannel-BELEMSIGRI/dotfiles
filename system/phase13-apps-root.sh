#!/usr/bin/env bash
# ╭──────────────────────────────────────────────────────────────────────╮
# │ phase13-apps-root.sh — applications de bureau (partie root)          │
# │ Usage : sudo phase13-apps-root.sh [--dry-run] [-h]                   │
# │  1. dépôt VirtualBox (Oracle) via extrepo, épinglé sur virtualbox-7.2│
# │  2. KVM : VMX activé à la demande (options kvm enable_virt_at_load=0)│
# │     sinon VirtualBox échoue (VERR_VMX_IN_VMX_ROOT_MODE, noyau ≥ 6.12)│
# │  3. lot packages/95-apps.list (simulation, 0 suppression/version)    │
# │  4. groupe vboxusers (USB dans les VM) ; politique Chromium sombre   │
# │ Prérequis : phase12 (build-essential pour le module DKMS vboxdrv).   │
# │ Partie utilisateur ensuite : dev-setup (applications par défaut…).   │
# │ Annulation : sudo apps-rollback-root.sh                              │
# ╰──────────────────────────────────────────────────────────────────────╯
set -euo pipefail
usage() { sed -n '3,12p' "$0" | sed 's/^# │ \{0,1\}//; s/ *│$//'; }
DRY=0
case ${1:-} in -h|--help) usage; exit 0 ;; --dry-run) DRY=1 ;; "") ;; *) usage >&2; exit 1 ;; esac
[[ $EUID -eq 0 ]] || { echo "à lancer en root (sudo)" >&2; exit 1; }
log() { printf '[apps] %s\n' "$*"; }
here=$(cd "$(dirname "$0")" && pwd)
USR=${SUDO_USER:?lancer via sudo depuis ton compte}

if (( DRY )); then
  tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
  grep -v '^virtualbox' "$here/packages/95-apps.list" > "$tmp"
  "$here/apt-install.sh" --dry-run "$tmp"
  log "(dry-run) + dépôt virtualbox, virtualbox-7.2 — rien n'a été modifié"; exit 0
fi
command -v gcc >/dev/null || { echo "lance d'abord phase12-devtools-root.sh (gcc requis par DKMS)" >&2; exit 1; }

# ── 1. Dépôt VirtualBox ─────────────────────────────────────────────────
if [[ ! -e /etc/apt/sources.list.d/extrepo_virtualbox.sources ]]; then
  command -v extrepo >/dev/null || apt-get install -y --no-install-recommends extrepo
  sed -i 's/^# *- contrib$/- contrib/; s/^# *- non-free$/- non-free/' /etc/extrepo/config.yaml
  for p in contrib non-free; do grep -q "^- $p\$" /etc/extrepo/config.yaml || printf -- '- %s\n' "$p" >> /etc/extrepo/config.yaml; done
  extrepo enable virtualbox
fi
cat > /etc/apt/preferences.d/virtualbox.pref <<'EOF'
# glass-soc phase 13 : seul virtualbox-7.2 est accepté depuis le dépôt Oracle
Package: *
Pin: origin "download.virtualbox.org"
Pin-Priority: -1

Package: virtualbox-7.2
Pin: origin "download.virtualbox.org"
Pin-Priority: 500
EOF
apt-get update -q

# ── 2. KVM et VirtualBox côte à côte ────────────────────────────────────
cat > /etc/modprobe.d/glass-soc-kvm.conf <<'EOF'
# glass-soc phase 13 : KVM n'active VT-x qu'au lancement d'une VM KVM, ce qui
# laisse VirtualBox l'utiliser le reste du temps (noyau >= 6.12).
options kvm enable_virt_at_load=0
EOF
if [[ $(cat /sys/module/kvm/parameters/enable_virt_at_load 2>/dev/null) == Y ]]; then
  if modprobe -r kvm_intel kvm 2>/dev/null; then modprobe kvm_intel; log "✔ modules KVM rechargés (VT-x libéré)"
  else log "modules KVM occupés : le réglage s'appliquera au prochain démarrage"; fi
fi

# ── 3. Paquets ──────────────────────────────────────────────────────────
"$here/apt-install.sh" "$here/packages/95-apps.list"
usermod -aG vboxusers "$USR"
log "✔ $USR ajouté à vboxusers (USB dans les VM, effet à la prochaine connexion)"

# ── 4. Chromium : barre sombre glass // SOC, pas de télémétrie ──────────
install -d /etc/chromium/policies/managed
cat > /etc/chromium/policies/managed/glass-soc.json <<'EOF'
{
  "BrowserThemeColor": "#0b0f14",
  "MetricsReportingEnabled": false,
  "DefaultBrowserSettingEnabled": false
}
EOF
log "✔ politique Chromium : /etc/chromium/policies/managed/glass-soc.json"
log "✔ terminé — puis, sans sudo : dev-setup"

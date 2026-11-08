# shellcheck shell=bash
# ── Intégrations outils ─────────────────────────────────────────────────
[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
# fzf : Ctrl+R historique, Ctrl+T fichiers, Alt+C répertoires
[ -r /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
[ -r /usr/share/doc/fzf/examples/completion.bash ] && . /usr/share/doc/fzf/examples/completion.bash
# zoxide : `z dossier` / `zi`
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# mkcd DIR : crée puis entre dans DIR
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }
# venv [DIR] : crée/active un virtualenv Python (jamais de pip global)
venv() {
  local d=${1:-.venv}
  [ -d "$d" ] || python3 -m venv "$d"
  # shellcheck disable=SC1091
  . "$d/bin/activate"
}
# extract FICHIER : décompresse selon l'extension
extract() {
  case $1 in
    *.tar.gz|*.tgz) tar xzf "$1" ;; *.tar.xz) tar xJf "$1" ;; *.tar.bz2) tar xjf "$1" ;;
    *.tar) tar xf "$1" ;; *.zip) unzip "$1" ;; *.gz) gunzip "$1" ;; *.xz) unxz "$1" ;;
    *) echo "format inconnu : $1" >&2; return 1 ;;
  esac
}

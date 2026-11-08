# shellcheck shell=bash
# ── Outils de développement (installés par dev-setup) ───────────────────
# Node.js : fnm change de version en entrant dans un dossier qui contient
# .nvmrc / .node-version / package.json "engines" (recherche récursive).
if command -v fnm >/dev/null; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --resolve-engines --shell bash)"
  eval "$(fnm completions --shell bash)"
fi
# Python : uv (projets : uv init, uv add pkg, uv run script.py)
command -v uv >/dev/null && eval "$(uv generate-shell-completion bash)"
# Docker
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'
# LaTeX : compilation continue (latexmk -pvc) avec XeLaTeX
alias texw='latexmk -xelatex -pvc -interaction=nonstopmode'
# imv : Debian ne fournit que imv-wayland / imv-x11 (+ lanceur libexec)
alias imv=/usr/libexec/imv/imv

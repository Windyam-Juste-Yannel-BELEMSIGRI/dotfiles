# shellcheck shell=bash
# ── Prompt : starship (Debian 13), sinon prompt maison de secours ───────
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
else
  PS1='\[\e[38;2;125;211;192m\]\u@\h\[\e[0m\] \[\e[38;2;168;168;174m\]\w\[\e[0m\]\n\[\e[38;2;125;211;192m\]❯\[\e[0m\] '
fi

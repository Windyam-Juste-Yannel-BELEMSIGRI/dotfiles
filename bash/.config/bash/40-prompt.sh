# shellcheck shell=bash
# ── Prompt : starship (Debian 13), sinon prompt maison de secours ───────
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
else
  PS1='\[\e[38;2;0;255;156m\]\u@\h\[\e[0m\] \[\e[38;2;125;136;152m\]\w\[\e[0m\]\n\[\e[38;2;0;255;156m\]❯\[\e[0m\] '
fi

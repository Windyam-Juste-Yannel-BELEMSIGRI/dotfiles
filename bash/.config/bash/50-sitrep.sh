# shellcheck shell=bash
# ── Rapport de situation : une fois par session TTY et une fois sous Sway
# Désactiver : export SITREP=0 dans ~/.config/bash/local.sh
if [ "${SITREP:-1}" = 1 ] && command -v sitrep >/dev/null; then
  __flag="${XDG_RUNTIME_DIR:-/tmp}/sitrep.${XDG_SESSION_ID:-0}.${WAYLAND_DISPLAY:-tty}"
  if [ ! -e "$__flag" ]; then
    : > "$__flag"; sitrep
  fi
  unset __flag
fi

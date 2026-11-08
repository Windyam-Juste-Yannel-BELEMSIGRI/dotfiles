# shellcheck shell=bash
# ── Environnement ────────────────────────────────────────────────────────
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":/usr/sbin:"*) ;; *) PATH="$PATH:/usr/sbin:/sbin" ;; esac
export PATH
export EDITOR=nvim VISUAL=nvim PAGER=less
export LESS='-R --mouse --use-color -Dd+c$ -Du+b$'
export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
export MANROFFOPT='-c'
export BAT_THEME=ansi
export HISTSIZE=50000 HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT='%F %T  '
# ignorer les commandes commençant par un espace (secrets ponctuels)
shopt -s histappend checkwinsize globstar cdspell autocd 2>/dev/null
# fzf : couleurs du thème
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded \
 --color=bg+:#2a2a2e,bg:-1,fg:#e8e8ec,hl:#7dd3c0,fg+:#e8e8ec,hl+:#8de3d0 \
 --color=info:#a8a8ae,prompt:#7dd3c0,pointer:#7dd3c0,marker:#8fb090,spinner:#7dd3c0,header:#7a9dc0,border:#3a3a40"

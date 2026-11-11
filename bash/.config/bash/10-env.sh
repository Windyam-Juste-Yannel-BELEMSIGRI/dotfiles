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
 --color=bg+:#121821,bg:-1,fg:#c5d1de,hl:#00ff9c,fg+:#c5d1de,hl+:#00e5ff \
 --color=info:#7d8898,prompt:#00ff9c,pointer:#00ff9c,marker:#00ff9c,spinner:#00ff9c,header:#4fc3f7,border:#1e2632"

# shellcheck shell=bash
# ── Alias ────────────────────────────────────────────────────────────────
# Noms Debian : fd → fdfind, bat → batcat
command -v fdfind >/dev/null && alias fd='fdfind'
command -v batcat >/dev/null && alias bat='batcat' && alias cat='batcat -pp'
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lh --git --group-directories-first --icons=auto --time-style=long-iso'
  alias la='eza -lha --git --group-directories-first --icons=auto --time-style=long-iso'
  alias lt='eza --tree --level=2 --icons=auto'
fi
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias vim='nvim' v='nvim'
alias ..='cd ..' ...='cd ../..'
alias df='df -h' du='du -h' free='free -h'
alias cp='cp -i' mv='mv -i'

# Système / services
alias sc='systemctl' scu='systemctl --user'
alias jf='journalctl -f' jfu='journalctl --user -f'
alias jerr='journalctl -p err -b'
alias failed='systemctl --failed; systemctl --user --failed'
alias upd='sudo apt update && apt list --upgradable'

# Réseau / sécurité (lecture seule)
alias ports='ss -tulpn'
alias conns='ss -tunp state established'
alias myip='curl -fsS https://api.ipify.org; echo'
alias lip='ip -br -c a'
alias authlog="journalctl -t sshd -t sshd-session -t sudo -t su -t login -n 100 --no-pager"
alias sshfails="journalctl --since -24h -t sshd -t sshd-session | grep -E 'Failed password|Invalid user'"

# Sway
alias swaycheck='sway -C && echo "config sway OK"'
alias keys='keys-help --print'
alias dots='cd ~/dotfiles && git status -sb'

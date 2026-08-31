#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
export PATH="$HOME/.local/bin:$PATH"

# --- bat / eza ---------------------------------------------------------------
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias catp='bat --paging=never --style=plain'   # sem número de linha, pra copiar
fi

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -l  --group-directories-first --icons=auto --git'
    alias la='eza -la --group-directories-first --icons=auto --git'
    alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
else
    alias ls='ls --color=auto'
fi

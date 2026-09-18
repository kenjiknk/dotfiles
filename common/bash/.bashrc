#
# ~/.bashrc
#
# Interactive bash. The environment (PATH, EDITOR, ...) is set at login in
# ~/.config/shell/env, not here — see that file for why.
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# Shared with zsh; see ~/.config/shell/aliases.
[ -r "$HOME/.config/shell/aliases" ] && . "$HOME/.config/shell/aliases"

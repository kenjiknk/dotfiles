#
# ~/.bash_profile  —  read at login only
#
# Mirrors ~/.zprofile: the same shared environment, so a bash login session
# gets the identical setup. See ~/.config/shell/env for why it is not in
# ~/.bashrc.
#

[ -r "$HOME/.config/shell/env" ] && . "$HOME/.config/shell/env"

[[ -f ~/.bashrc ]] && . ~/.bashrc

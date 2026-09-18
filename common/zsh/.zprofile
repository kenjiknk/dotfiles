#
# ~/.zprofile  —  read at login only
#
# ly runs /etc/ly/setup.sh before the session, and that loads this file for zsh
# shells. So whatever lands here applies to sway and, by inheritance, to every
# program opened inside the session — which is exactly why the environment
# lives in one shared file instead of in ~/.zshrc.
#

[ -r "$HOME/.config/shell/env" ] && . "$HOME/.config/shell/env"

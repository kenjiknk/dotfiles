# powerlevel10k instant prompt — MUST stay at the top of the file.
# Put nothing above this that writes to the screen or asks for input.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#
# ~/.zshrc  —  oh-my-zsh
#

# PATH, EDITOR, VISUAL and BROWSER live in ~/.config/shell/env, read at login —
# not here: this file is read by interactive shells only, so nothing exported
# in it reaches the programs sway starts.

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# zsh-syntax-highlighting MUST be last in the list
plugins=(
    git                     # git aliases and completion
    sudo                    # ESC ESC repeats the command with sudo in front
    extract                 # "x file.tar.gz" extracts any format
    colored-man-pages
    archlinux               # pacman/yay aliases
    command-not-found       # suggests the package (needs pkgfile)
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# --- history -----------------------------------------------------------------
# omz already sets HISTFILE, share_history, hist_ignore_dups/space and
# extended_history; this only raises what is kept on disk
SAVEHIST=50000
setopt HIST_REDUCE_BLANKS

# --- aliases -----------------------------------------------------------------
# Shared with bash; see ~/.config/shell/aliases. Sourced AFTER oh-my-zsh on
# purpose: it defines an `alias ls` of its own, and the last one wins.
[ -r "$HOME/.config/shell/aliases" ] && . "$HOME/.config/shell/aliases"

# --- powerlevel10k -----------------------------------------------------------
# run "p10k configure" to (re)generate; the file below stores those choices
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Instant prompt do powerlevel10k — DEVE ficar no topo do arquivo.
# Não coloque nada acima daqui que escreva na tela ou peça input.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#
# ~/.zshrc  —  oh-my-zsh
#

export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim
export VISUAL=nvim
export BROWSER=zen-browser

ZSH_THEME="powerlevel10k/powerlevel10k"

# zsh-syntax-highlighting DEVE ser o último da lista
plugins=(
    git                     # aliases e completion de git
    sudo                    # ESC ESC repete o comando com sudo na frente
    extract                 # "x arquivo.tar.gz" extrai qualquer formato
    colored-man-pages
    archlinux               # aliases de pacman/yay
    command-not-found       # sugere o pacote (precisa de pkgfile)
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# --- histórico ---------------------------------------------------------------
# o omz já define HISTFILE, share_history, hist_ignore_dups/space e
# extended_history; aqui só aumento o que fica salvo em disco
SAVEHIST=50000
setopt HIST_REDUCE_BLANKS

# --- aliases -----------------------------------------------------------------
# precisam vir DEPOIS do source: o omz define seu próprio "alias ls"
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias catp='bat --paging=never --style=plain'   # sem número de linha, pra copiar
fi

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -l  --group-directories-first --icons=auto --git'
    alias la='eza -la --group-directories-first --icons=auto --git'
    alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
fi

# --- powerlevel10k -----------------------------------------------------------
# rode "p10k configure" pra (re)gerar; o arquivo abaixo guarda suas escolhas
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

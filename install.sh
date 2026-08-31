#!/usr/bin/env bash
#
# Deploys this configuration into $HOME as symlinks.
#
#   common/            configs that work on any machine
#   hosts/<hostname>/  configs tied to one specific machine
#
# Both are stowed; the host layer is skipped when there is no directory for
# this machine. This script installs no packages and needs no root — the
# programs these configs belong to must already be present (see the README).
#
# Safe to re-run: nothing is duplicated, nothing is overwritten without a backup.
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
# `hostname` vem do inetutils, que nem toda instalação tem; uname -n é coreutils.
# DOTFILES_HOST permite forçar outra camada, útil para testar.
HOST="${DOTFILES_HOST:-$(hostnamectl --static 2>/dev/null || cat /etc/hostname 2>/dev/null || uname -n)}"

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

command -v stow >/dev/null || { warn "stow não encontrado. Instale-o e rode de novo."; exit 1; }

# --- pré-requisitos do zsh --------------------------------------------------
# Clonados à mão de propósito: o instalador oficial do oh-my-zsh sobrescreve o
# ~/.zshrc, que é justamente o arquivo que este repositório entrega.
[[ -d "$HOME/.oh-my-zsh" ]] || {
    log "Clonando oh-my-zsh"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
}
p10k="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
[[ -d "$p10k" ]] || {
    log "Clonando powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k"
}

# plugins vêm do gerenciador de pacotes; symlink em vez de clone, para que ele
# siga cuidando das atualizações
log "Ligando plugins do zsh ao oh-my-zsh"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
for plug in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ -d "/usr/share/zsh/plugins/$plug" ]]; then
        ln -sfn "/usr/share/zsh/plugins/$plug" "$HOME/.oh-my-zsh/custom/plugins/$plug"
    else
        warn "$plug não instalado; o .zshrc vai ignorá-lo silenciosamente"
    fi
done

# --- o que será instalado ---------------------------------------------------
layers=("$DOTFILES/common")
if [[ -d "$DOTFILES/hosts/$HOST" ]]; then
    layers+=("$DOTFILES/hosts/$HOST")
    log "Camada específica encontrada: hosts/$HOST"
else
    warn "Sem hosts/$HOST — instalando apenas common/."
    warn "Configurações de hardware (teclado, touchpad, bateria) ficarão de fora."
fi

# --- backup de qualquer arquivo que o stow fosse sobrescrever ---------------
log "Procurando conflitos"
conflitos=0
for layer in "${layers[@]}"; do
    for pkg in "$layer"/*/; do
        [[ -d "$pkg" ]] || continue
        while IFS= read -r -d '' src; do
            rel="${src#"$pkg"}"
            dst="$HOME/$rel"
            if [[ -e "$dst" && ! -L "$dst" ]]; then
                mkdir -p "$(dirname "$BACKUP/$rel")"
                mv "$dst" "$BACKUP/$rel"
                conflitos=$((conflitos + 1))
            fi
        done < <(find "$pkg" -type f -print0)
    done
done
(( conflitos > 0 )) && log "$conflitos arquivo(s) movidos para $BACKUP"

# --- symlinks ---------------------------------------------------------------
for layer in "${layers[@]}"; do
    pkgs=()
    for d in "$layer"/*/; do
        [[ -d "$d" ]] && pkgs+=("$(basename "$d")")
    done
    if (( ${#pkgs[@]} == 0 )); then
        warn "${layer#"$DOTFILES"/} está vazia, nada a instalar"
        continue
    fi
    log "stow ${layer#"$DOTFILES"/}: ${pkgs[*]}"
    stow --dir="$layer" --target="$HOME" --restow "${pkgs[@]}"
done

# --- shell padrão -----------------------------------------------------------
# sem isso o ~/.zshrc entregue aqui nunca é carregado
if [[ "$SHELL" != */zsh ]]; then
    if command -v zsh >/dev/null; then
        log "Mudando o shell de login para zsh (pede a SUA senha, não root)"
        chsh -s "$(command -v zsh)" || warn "chsh falhou; rode manualmente"
    else
        warn "zsh não instalado; shell de login não alterado"
    fi
fi

echo
log "Pronto. Faça logout e login de novo."

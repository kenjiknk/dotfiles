#!/usr/bin/env bash
#
# Instala esta configuração numa máquina Arch com Sway.
# Seguro para reexecutar: nada é duplicado, nada é sobrescrito sem backup.
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

PACKAGES=(sway waybar kitty foot mako fuzzel swayidle swaylock xdg
          nwg-displays yazi zathura gtk zsh bash claude scripts)

log()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

command -v pacman >/dev/null || { warn "Isto só roda em Arch e derivados."; exit 1; }

# --- 1. pacotes dos repositórios oficiais -----------------------------------
log "Instalando pacotes oficiais (pkglist.txt)"
sudo pacman -S --needed --noconfirm stow < /dev/null
sudo pacman -S --needed --noconfirm - < "$DOTFILES/packages/pkglist.txt"

# --- 2. yay + pacotes do AUR ------------------------------------------------
if ! command -v yay >/dev/null; then
    log "yay não encontrado, compilando yay-bin"
    sudo pacman -S --needed --noconfirm git base-devel < /dev/null
    tmp="$(mktemp -d)"
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
fi

aur=$(grep -vx 'yay-bin' "$DOTFILES/packages/aurlist.txt" | tr '\n' ' ')
if [[ -n "${aur// }" ]]; then
    log "Instalando pacotes do AUR: $aur"
    # shellcheck disable=SC2086
    yay -S --needed --noconfirm $aur
fi

# --- 3. oh-my-zsh e powerlevel10k -------------------------------------------
# clonados à mão de propósito: o instalador oficial sobrescreve o ~/.zshrc
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log "Clonando oh-my-zsh"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

p10k="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [[ ! -d "$p10k" ]]; then
    log "Clonando powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k"
fi

# plugins vêm do pacman; symlink em vez de clone para o pacman seguir atualizando
log "Ligando plugins do zsh ao oh-my-zsh"
mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
for plug in zsh-autosuggestions zsh-syntax-highlighting; do
    [[ -d "/usr/share/zsh/plugins/$plug" ]] &&
        ln -sfn "/usr/share/zsh/plugins/$plug" "$HOME/.oh-my-zsh/custom/plugins/$plug"
done

# --- 4. backup de qualquer arquivo que o stow fosse sobrescrever ------------
log "Procurando conflitos"
conflitos=0
for pkg in "${PACKAGES[@]}"; do
    [[ -d "$DOTFILES/$pkg" ]] || continue
    while IFS= read -r -d '' src; do
        rel="${src#"$DOTFILES/$pkg/"}"
        dst="$HOME/$rel"
        if [[ -e "$dst" && ! -L "$dst" ]]; then
            mkdir -p "$(dirname "$BACKUP/$rel")"
            mv "$dst" "$BACKUP/$rel"
            conflitos=$((conflitos + 1))
        fi
    done < <(find "$DOTFILES/$pkg" -type f -print0)
done
(( conflitos > 0 )) && log "$conflitos arquivo(s) movidos para $BACKUP"

# --- 5. symlinks ------------------------------------------------------------
log "Criando symlinks com stow"
cd "$DOTFILES"
stow --restow --target="$HOME" "${PACKAGES[@]}"

# --- 6. índice do pkgfile (command-not-found) -------------------------------
if command -v pkgfile >/dev/null && [[ ! -f /var/cache/pkgfile/core.files ]]; then
    log "Baixando índice do pkgfile"
    sudo pkgfile --update
    sudo systemctl enable --now pkgfile-update.timer
fi

# --- 7. shell padrão --------------------------------------------------------
if [[ "$SHELL" != */zsh ]]; then
    log "Mudando o shell de login para zsh (vai pedir sua senha)"
    chsh -s /usr/bin/zsh || warn "chsh falhou; rode manualmente: chsh -s /usr/bin/zsh"
fi

echo
log "Pronto. Faça logout e login de novo para o zsh e o Sway assumirem."
echo "   Monitores:  nwg-displays  (veja a nota sobre 'include' no README)"

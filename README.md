# dotfiles

Sway setup on Arch Linux, originally built on a ThinkPad E14 Gen 6 (AMD Ryzen 5 7535U).

Originally derived from [vyrx-dev/dotfiles](https://github.com/vyrx-dev/dotfiles),
then reworked: different terminal, Brazilian keyboard, power profiles, zsh with
oh-my-zsh and powerlevel10k, and a number of upstream bugs fixed along the way.

## Install on a fresh machine

> Read `install.sh` before running it. It installs packages, changes your login
> shell, and creates symlinks in `$HOME`.

```sh
git clone https://github.com/<user>/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then log out and back in.

The script is idempotent — safe to re-run. Any real file it would overwrite is
moved to `~/.dotfiles-backup-<timestamp>/` first, never deleted.

What it does:

1. Installs `packages/pkglist.txt` via pacman and `packages/aurlist.txt` via yay
   (bootstrapping yay from source if missing)
2. Clones oh-my-zsh and powerlevel10k, and symlinks the pacman-installed zsh
   plugins into `~/.oh-my-zsh/custom/plugins`
3. Backs up conflicting files, then deploys every package with GNU Stow
4. Downloads the pkgfile index and enables its update timer
5. Switches the login shell to zsh

## Layout

GNU Stow packages — each directory mirrors `$HOME`, so `stow sway` links
`sway/.config/sway/config` to `~/.config/sway/config`.

```
sway/          compositor, keybindings, input
waybar/        status bar (single flattened theme, no theme switcher)
mako/          notifications
kitty/         terminal
foot/          terminal (fallback; kitty is the default)
fuzzel/        application launcher
swayidle/      idle -> lock -> screen off
swaylock/      lock screen (solid black)
nwg-displays/  monitor layout GUI
yazi/          file manager theme
zathura/       PDF reader
gtk/           dark mode for GTK 3 and 4
zsh/           zsh + oh-my-zsh + powerlevel10k
bash/          bash fallback, same aliases
claude/        Claude Code settings and custom statusline
scripts/       helper scripts, deployed to ~/Scripts
packages/      pacman and AUR package lists
```

Deploy a single package with `stow <name>`, remove it with `stow -D <name>`.

## Per-machine notes

Nothing in these configs hardcodes an output name, a network interface or a
`/sys` path, so they transfer as-is. The exceptions:

- **Monitors.** `~/.config/sway/outputs` and `~/.config/sway/workspaces` are
  written by `nwg-displays` and are specific to each machine, so they are not
  tracked. To use them, add `include ~/.config/sway/outputs` to
  `~/.config/sway/config` — it is not there by default.
- **Desktop machines.** Drop the `battery` module from `waybar/config.jsonc`,
  the `input type:touchpad` block from `sway/config`, and the
  `custom/power-profile` module plus its two scripts (they need
  `power-profiles-daemon`).
- **Keyboard.** Layout is `br` with the `thinkpad` variant: on Brazilian
  ThinkPads the `/ ?` key sits where right Ctrl normally is. Change this in
  `sway/.config/sway/config` if your keyboard differs.
- **`last-updated.sh`** reads `/var/log/pacman.log`, so it is Arch-specific.
- **`pkglist.txt`** includes hardware packages for AMD (`amd-ucode`,
  `vulkan-radeon`, `linux-firmware-amdgpu`). Swap them for the Intel or NVIDIA
  equivalents if needed.

## Dependencies

**Core:** sway, waybar, mako, kitty, fuzzel, swayidle, swaylock, yazi, zathura,
zathura-pdf-mupdf, nwg-displays

**Called by the bar and the scripts:** btop, duf, pamixer, pavucontrol, nmgui
(AUR), power-profiles-daemon, network-manager-applet, grim, brightnessctl,
flameshot

**Shell:** zsh, oh-my-zsh, powerlevel10k, zsh-autosuggestions,
zsh-syntax-highlighting, zsh-completions, bat, eza, pkgfile

**Fonts:** inter-font, ttf-jetbrains-mono-nerd

The full list lives in `packages/`.

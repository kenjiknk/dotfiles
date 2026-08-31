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

On the ThinkPad E14 Gen 6 this repo was built on — AMD, LUKS + btrfs — add
`--this-machine` to also install the hardware- and storage-specific packages.

Then log out and back in.

The script is idempotent — safe to re-run. Any real file it would overwrite is
moved to `~/.dotfiles-backup-<timestamp>/` first, never deleted.

What it does:

1. Installs `packages/pkglist.txt` via pacman and `packages/aurlist.txt` via yay
   (bootstrapping yay from source if missing). `packages/pkglist-thinkpad.txt`
   is skipped unless `--this-machine` is given
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
xdg/           default applications (Zen browser, Neovim, zathura)
zsh/           zsh + oh-my-zsh + powerlevel10k
bash/          bash fallback, same aliases
claude/        Claude Code settings and custom statusline
scripts/       helper scripts, deployed to ~/Scripts
packages/      pacman and AUR package lists
```

### Package lists

| File | Contents |
|---|---|
| `pkglist.txt` | Portable — safe on any Arch machine |
| `pkglist-thinkpad.txt` | AMD microcode and graphics, LUKS/btrfs tooling, snapper, `linux-lts`. Opt-in via `--this-machine` |
| `aurlist.txt` | AUR packages, installed with yay |

The split matters: `amd-ucode` is the wrong microcode on an Intel machine,
snapper without a btrfs subvolume layout has nothing to snapshot, and
`linux-lts` costs ~275 MiB of ESP that a smaller `/boot` may not have.

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
- **Default editor.** `xdg/.local/share/applications/nvim.desktop` overrides
  the packaged entry, which is `Terminal=true`. Sway registers no terminal for
  xdg-open to resolve, so it calls `kitty -e nvim` explicitly. Change the
  terminal there if you switch away from kitty.
- **Symlinks that programs may replace.** Stow deploys files as symlinks, but a
  program that saves by writing a temp file and renaming it over the target
  destroys the link — silently, since the repo copy stays untouched and
  `git status` shows nothing. Known candidates here: `nwg-displays` (rewrites
  its own config on close), `p10k configure` (rewrites `~/.p10k.zsh`), and
  Claude Code (rewrites `~/.claude/settings.json` when settings change). After
  using any of them, run `stow --restow <package>` to relink. `find ~ -maxdepth
  4 -path "*/.config/*" -type f -newer README.md` helps spot them.
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

# dotfiles

Sway on Arch Linux. Configuration only — how things look, and how the tools
used day to day behave.

Originally derived from [vyrx-dev/dotfiles](https://github.com/vyrx-dev/dotfiles),
then reworked: different terminal, Brazilian keyboard, power profiles, zsh with
oh-my-zsh and powerlevel10k, and a number of upstream bugs fixed along the way.

## Scope

This repo does not provision a system. No package lists, no system services,
nothing under `/etc`. Install the programs first (see [Dependencies](#dependencies)),
then deploy the configs.

Everything is split in two:

| | |
|---|---|
| `common/` | Works on any machine. Copy it to a new computer and it just runs |
| `hosts/<hostname>/` | Tied to one specific machine: keyboard layout, touchpad, battery, monitor arrangement |

`install.sh` always deploys `common/`, and adds `hosts/<hostname>/` when a
directory for the current machine exists. On a machine with no host directory
you get the full environment minus the hardware-specific bits.

## Install

> Read `install.sh` before running it. It creates symlinks in `$HOME` and may
> change your login shell. It installs nothing and needs no root.

```sh
git clone https://github.com/<user>/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then log out and back in.

Safe to re-run. Any real file it would overwrite is moved to
`~/.dotfiles-backup-<timestamp>/` first, never deleted.

What it does:

1. Clones oh-my-zsh and powerlevel10k, and symlinks the packaged zsh plugins
   into `~/.oh-my-zsh/custom/plugins`
2. Backs up conflicting files, then deploys both layers with GNU Stow
3. Switches the login shell to zsh

## Layout

GNU Stow packages — each directory mirrors `$HOME`, so the `sway` package links
`common/sway/.config/sway/config` to `~/.config/sway/config`.

```
common/
  sway/          compositor, keybindings, colours
  waybar/        bar styling (style.css)
  mako/          notifications
  kitty/         terminal
  foot/          terminal (fallback; kitty is the default)
  fuzzel/        application launcher
  swayidle/      idle -> lock -> screen off
  swaylock/      lock screen (solid black)
  yazi/          file manager theme
  zathura/       PDF reader
  gtk/           dark mode for GTK 3 and 4
  xdg/           default applications (browser, editor, PDF)
  zsh/           zsh + oh-my-zsh + powerlevel10k
  bash/          bash fallback, same aliases
  claude/        Claude Code settings and custom statusline
  scripts/       powermenu, deployed to ~/Scripts

hosts/thinkpad/
  sway/          keyboard layout, touchpad, power-profile binding
  waybar/        module list (config.jsonc): battery, power profile, updates
  nwg-displays/  monitor layout tool
  scripts/       power-profile-menu, power-profile-status, last-updated.sh
```

Deploy one package with `stow --dir=common --target="$HOME" kitty`, remove it
with `-D` instead of the default.

### How the split works

**sway** uses its own `include`. `common/sway` ends with
`include ~/.config/sway/local`, and that file comes from `hosts/<hostname>/sway`.
A machine with no host directory simply has no `local` file, and sway carries on
— everything portable still applies.

**waybar** cannot merge module lists across files (`include` replaces arrays
rather than merging them), so the split is by file instead: `style.css` is
common, `config.jsonc` is per-host. A new machine inherits the look and declares
its own modules.

## Adding a machine

```sh
mkdir -p hosts/$(hostnamectl --static)/sway/.config/sway
```

Put its keyboard, touchpad and output settings in a `local` file there, and a
`waybar/.config/waybar/config.jsonc` with the modules that machine actually has.
Then re-run `./install.sh`.

## Notes

- **Symlinks that programs may replace.** Stow deploys files as symlinks, but a
  program that saves by writing a temp file and renaming it over the target
  destroys the link — silently, since the repo copy stays untouched and
  `git status` shows nothing. Known candidates here: `nwg-displays` (rewrites
  its own config on close), `p10k configure` (rewrites `~/.p10k.zsh`), and
  Claude Code (rewrites `~/.claude/settings.json` when settings change). After
  using any of them, run `./install.sh` again to relink.
- **Keyboard.** `hosts/thinkpad` uses layout `br` with the `thinkpad` variant:
  on Brazilian ThinkPads the `/ ?` key sits where right Ctrl normally is.
- **`last-updated.sh`** reads `/var/log/pacman.log`, so it is Arch-specific. It
  lives under `hosts/` for that reason.
- **Default editor.** `common/xdg` ships an `nvim.desktop` that overrides the
  packaged one, which is `Terminal=true`. Sway registers no terminal for
  `xdg-open` to resolve, so the override calls `kitty -e nvim` explicitly.
  Change the terminal there if you switch away from kitty.
- No secrets are tracked. `.gitignore` blocks SSH keys, shell history and
  browser profiles.

## Dependencies

Install these before running `install.sh` — this repo configures them, it does
not install them.

**Compositor and desktop:** sway, swaybg, swayidle, swaylock, waybar, mako,
fuzzel, nwg-displays, wl-clipboard, grim, slurp, xdg-desktop-portal-wlr

**Terminals and shell:** kitty, foot, zsh, zsh-autosuggestions,
zsh-syntax-highlighting, zsh-completions, bat, eza

**Tools:** yazi, zathura, zathura-pdf-mupdf, btop, duf, brightnessctl, pamixer,
pavucontrol

**Called by the bar and the scripts:** power-profiles-daemon, pkgfile

**Fonts:** inter-font, ttf-jetbrains-mono-nerd, noto-fonts, noto-fonts-emoji

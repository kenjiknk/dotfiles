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

Deploy `common/` always, and `hosts/<hostname>/` on the machine it belongs to.
A machine with no host directory gets the full environment minus the
hardware-specific bits.

## Install

Four steps, all by hand. Nothing here needs root.

```sh
git clone https://github.com/<user>/dotfiles ~/dotfiles
```

**1. oh-my-zsh and powerlevel10k.** Cloned directly, because the official
oh-my-zsh installer overwrites `~/.zshrc` — the very file this repo deploys.

```sh
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ~/.oh-my-zsh/custom/themes/powerlevel10k
```

**2. zsh plugins.** These come from pacman, so they are symlinked rather than
cloned and keep getting updated with the system.

```sh
mkdir -p ~/.oh-my-zsh/custom/plugins
ln -sfn /usr/share/zsh/plugins/zsh-autosuggestions   ~/.oh-my-zsh/custom/plugins/
ln -sfn /usr/share/zsh/plugins/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/
```

**3. Deploy.** Run from inside each layer, so `*` expands to its package names.
`--target` is needed because stow would otherwise aim at the layer's parent.
Keep `--no-folding` — see the note below.

```sh
cd ~/dotfiles/common          && stow --target="$HOME" --no-folding *
cd ~/dotfiles/hosts/thinkpad  && stow --target="$HOME" --no-folding *
```

Add `--restow` to redeploy after `git pull` or a renamed file; it removes the
stale links before making the new ones. If a real file is sitting where a
symlink should go, stow refuses and names it — move it aside yourself and run
the command again.

**4. Login shell.**

```sh
chsh -s /usr/bin/zsh
```

Then log out and back in.

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
  shell/         environment and aliases shared by both shells
  zsh/           zsh + oh-my-zsh + powerlevel10k
  bash/          bash fallback
  claude/        Claude Code settings and custom statusline
  scripts/       powermenu, deployed to ~/Scripts

hosts/thinkpad/
  sway/          keyboard layout, touchpad, power-profile binding
  shell/         env.local: the evdi/swaynag workaround for this dock
  waybar/        module list (config.jsonc): battery, power profile, updates
  nwg-displays/  monitor layout tool
  scripts/       touchpad, power-profile-menu, power-profile-status,
                 last-updated.sh
```

Deploy one package with
`stow --dir=common --target="$HOME" --no-folding kitty`, remove it with `-D`
instead of the default. Keep `--no-folding` — see the note below.

### How the split works

**sway** uses its own `include`. `common/sway` ends with
`include ~/.config/sway/local`, and that file comes from `hosts/<hostname>/sway`.
A machine with no host directory simply has no `local` file, and sway carries on
— everything portable still applies.

**shell** keeps one copy of everything both shells need.
`common/shell/.config/shell/env` holds the login environment and
`.../shell/aliases` the interactive aliases; `.zprofile`/`.bash_profile` source
the first, `.zshrc`/`.bashrc` the second. `env` ends by sourcing
`~/.config/shell/env.local`, which is where the host layer puts per-machine
variables — the same trick sway uses with its `local`.

The split matters more than it looks. `~/.zshrc` is read by *interactive*
shells only, so anything exported there never reaches waybar, fuzzel, a
keybinding or an `xdg-open` handler — the login shell is the parent of the whole
graphical session, and only what it exports is inherited.

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
Environment variables that apply to that machine only go in
`shell/.config/shell/env.local`. Then stow that layer, as in step 3 above.

## Notes

- **Symlinks that programs may replace.** Stow deploys files as symlinks, but a
  program that saves by writing a temp file and renaming it over the target
  destroys the link — silently, since the repo copy stays untouched and
  `git status` shows nothing. Known candidates here: `nwg-displays` (rewrites
  its own config on close), `p10k configure` (rewrites `~/.p10k.zsh`), and
  Claude Code (rewrites `~/.claude/settings.json` when settings change). After
  using any of them, re-run the `stow` commands from step 3 with `--restow`.
- **`--no-folding`.** Pass it to every `stow` call. Without it, stow replaces a
  directory it is the sole owner of with a single symlink to the package —
  "tree folding". Both layers write into `~/.config/shell` and `~/Scripts`, so
  the second one then meets a folded symlink it does not own and aborts the
  whole run. Real directories holding one symlink per file cost nothing and let
  the layers stack.
- **Wallpaper.** `common/sway` points at `~/Pictures/Wallpaper/nujabes2-dark.png`
  — sway expands the `~`, so no user name is baked in, but the image itself is
  not tracked here (this repo is configuration only). A machine without it gets
  the `#000000` fallback colour instead of a broken session.
- **Monitors.** `nwg-displays` is kept for *finding* a layout, not for applying
  one: the `~/.config/sway/outputs` it writes is gitignored and deliberately not
  `include`d, because it keys screens by connector name and the two DisplayLink
  outputs swap between `DVI-I-1` and `DVI-I-2` across reconnects. Drag the
  screens there, then transcribe the geometry into the `screens` array in
  `dock-monitors`, which matches on `make model serial` instead.
- **Touchpad.** It starts disabled — `hosts/thinkpad/sway` sets `events disabled`
  on `type:touchpad`. `~/Scripts/touchpad` (bound to `$mod+Shift+t`) turns it on,
  off, or flips it; `touchpad status` prints the current state. Sway re-applies
  the input block on each config reload and each time the device reappears, so
  `$mod+Shift+c` and a resume from suspend both put it back to disabled. The
  TrackPoint is untouched.
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
- **No licence, on purpose.** There is no `LICENSE` file, so default copyright
  applies: all rights reserved, nothing here is granted for reuse. Parts derive
  from [vyrx-dev/dotfiles](https://github.com/vyrx-dev/dotfiles) and
  `yazi/theme.toml` is theirs ("Symphony by vyrx"), so check their terms before
  lifting anything out of here.

## Dependencies

Install these first — this repo configures them, it does not install them.

**Compositor and desktop:** swayfx (not plain sway — `hosts/thinkpad/sway`
uses `blur` and `dim_inactive_colors`, which sway rejects), swaybg, swayidle,
swaylock, waybar, mako, fuzzel, autotiling, nwg-displays, wl-clipboard, grim,
slurp, xdg-desktop-portal-wlr, xdg-desktop-portal-gtk

**Deploying this repo:** stow, git

**Terminals and shell:** kitty, foot, zsh, zsh-autosuggestions,
zsh-syntax-highlighting, zsh-completions, bat, eza

**Tools:** yazi, zathura, zathura-pdf-mupdf, btop, duf, brightnessctl, pamixer,
pavucontrol

**Called by the bar, the keybindings and the scripts:** power-profiles-daemon,
pkgfile, playerctl (media keys and the mpris module), libpulse (`pactl`),
libnotify (`notify-send`), network-manager-applet (tray icon), nmgui (clicking
the network module), glib2 (`gsettings`), python (the statusline and the
`dock-monitors`/`touchpad` scripts), qt6-base (the Qt/GTK theme bridge)

**Fonts:** inter-font, ttf-jetbrains-mono-nerd, ttf-dejavu (sway's tab and
stack titles), noto-fonts, noto-fonts-emoji

# dotfiles

i3 on X11, written to run on any distro. Configuration — how things look, and
how the tools used day to day behave — plus the wallpapers it rotates through. Developed on Arch; the baseline is
whatever an LTS distro from 2022 on ships (see [Portability](#portability)).

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
| `hosts/<hostname>/` | Tied to one specific machine: keyboard layout, monitor arrangement |

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

Then log out and pick the **i3** session in the display manager (ly lists it
once `i3-wm` is installed). Without a display manager, `startx` with
`exec i3` in `~/.xinitrc` does the same.

## Layout

GNU Stow packages — each directory mirrors `$HOME`, so the `i3` package links
`common/i3/.config/i3/config` to `~/.config/i3/config`.

```
common/
  i3/            window manager, keybindings, colours, the bar block
  i3blocks/      status line: config plus one script per block
  dunst/         notifications
  rofi/          application launcher and the menus in ~/Scripts
  picom/         compositor: blur, dimmed unfocused windows, animations (optional)
  kitty/         terminal
  yazi/          file manager theme
  zathura/       PDF reader
  gtk/           dark mode for GTK 3 and 4
  xdg/           default applications (browser, editor, PDF)
  shell/         environment and aliases shared by both shells
  zsh/           zsh + oh-my-zsh + powerlevel10k
  bash/          bash fallback
  claude/        Claude Code settings and custom statusline
  wallpapers/    the images ~/Scripts/wallpaper picks from (~/Pictures/Wallpaper)
  scripts/       powermenu, screenshot, volume, kbd-layout, keyboard-watch,
                 touchpad, power-profile-menu, wallpaper — deployed to ~/Scripts

hosts/thinkpad/
  i3/            keyboard layout, touchpad off at login, dock watcher
  scripts/       dock-monitors
```

Deploy one package with
`stow --dir=common --target="$HOME" --no-folding kitty`, remove it with `-D`
instead of the default. Keep `--no-folding` — see the note below.

### How the split works

**i3** uses its own `include`. `common/i3` ends with
`include ~/.config/i3/local`, and that file comes from `hosts/<hostname>/i3`.
A machine with no host directory simply has no `local` file, which i3 accepts
silently — everything portable still applies.

**shell** keeps one copy of everything both shells need.
`common/shell/.config/shell/env` holds the login environment and
`.../shell/aliases` the interactive aliases; `.zprofile`/`.bash_profile` source
the first, `.zshrc`/`.bashrc` the second. `env` ends by sourcing
`~/.config/shell/env.local`, where a host layer can put per-machine variables —
the same trick i3 uses with its `local`. No host needs one at the moment.

The split matters more than it looks. `~/.zshrc` is read by *interactive*
shells only, so anything exported there never reaches the bar, rofi, a
keybinding or an `xdg-open` handler — the login shell is the parent of the whole
graphical session, and only what it exports is inherited.

**The bar** needs no split at all. Every i3blocks block prints nothing when the
machine lacks what it reports — no battery, no power-profiles-daemon, no
`pacman.log` — and i3bar leaves an empty block out. One config, every machine.

**Scripts** follow the same rule: `touchpad` finds touchpads by capability and
exits quietly without one, `power-profile-menu` says so when the daemon is
missing. Only `dock-monitors`, which names this desk's three screens, is per-host.

## Adding a machine

Nothing is required — `common/` alone is a complete session. For hardware
settings, create the host layer:

```sh
mkdir -p hosts/$(hostnamectl --static)/i3/.config/i3
```

Put its keyboard layout (`~/Scripts/kbd-layout set ...`), touchpad default and
monitor setup in a `local` file there, then stow that layer, as in step 3 above.

## Portability

The point of this setup is that the same `common/` runs anywhere. What that
rests on:

- **X11 and i3.** i3's config syntax has barely moved in a decade, and every
  distro packages it. i3bar ships with i3, so the bar cannot drift out of step
  with the window manager.
- **Baseline: i3 4.22** (Debian 12, Ubuntu 24.04, Fedora 38, and newer). That is
  the first release with gaps built in. On older i3 — Ubuntu 22.04 has 4.20 —
  the session still loads; i3 only flags the two `gaps`/`smart_gaps` lines it
  does not know, and the rest applies. For the real thing on an old Ubuntu, the
  i3 project's own apt repository carries current releases.
- **Only stable tools.** setxkbmap, xinput, xrandr, xset and pactl instead of
  anything distro-specific. rofi, dunst and picom configs stick to syntax their
  2022-era versions (rofi 1.7, dunst 1.8, picom 9) understand; the few newer
  options (dunst's `sort = update`, picom's animations, GTK 4.20's colour-scheme
  key) are ignored by older versions.
- **Optional extras fail quietly.** picom, autotiling, xbanish, nm-applet and
  the wallpaper are started so that a missing one costs only that feature.

## Notes

- **Symlinks that programs may replace.** Stow deploys files as symlinks, but a
  program that saves by writing a temp file and renaming it over the target
  destroys the link — silently, since the repo copy stays untouched and
  `git status` shows nothing. Known candidates here: `p10k configure` (rewrites
  `~/.p10k.zsh`) and Claude Code (rewrites `~/.claude/settings.json` when
  settings change). After using either, re-run the `stow` commands from step 3
  with `--restow`.
- **`--no-folding`.** Pass it to every `stow` call. Without it, stow replaces a
  directory it is the sole owner of with a single symlink to the package —
  "tree folding". Both layers write into `~/Scripts`, so the second one then
  meets a folded symlink it does not own and aborts the whole run. Real
  directories holding one symlink per file cost nothing and let the layers
  stack.
- **`$mod+Shift+c` restarts i3** in place, keeping every window. Not a plain
  reload: i3 runs `exec_always` lines — wallpaper, touchpad off, keyboard
  settings — only on a restart, unlike sway, which ran them on reload.
- **Wallpaper.** Every login and restart, `~/Scripts/wallpaper` picks a
  random image from `~/Pictures/Wallpaper` (never the one already showing). One
  that fits the screen is shown at its original size on black; a larger one is
  scaled down to fit — never cropped or stretched. The `wallpapers` package
  links the tracked images there; files dropped into the folder by hand join
  the rotation too, without being committed.
- **Idle and lock.** Lock at 5 minutes, screens off at 5.5, lock before
  suspend: `xset` sets the timers and xss-lock runs i3lock. Lock by hand with
  `loginctl lock-session` (what the power menu does).
- **Monitors.** `arandr` is the tool for *finding* a layout, not for applying
  one: its saved scripts key screens by output name, and the two DisplayLink
  outputs swap names across reconnects. Drag the screens there, then transcribe
  the geometry into the `screens` array in `dock-monitors`, which matches on the
  EDID's `make model serial` instead and watches udev for hotplugs.
- **DisplayLink under X.** Each dock screen sits on its own evdi provider, which
  X leaves detached until `xrandr --setprovideroutputsource` hands it to the GPU.
  `dock-monitors` does that before arranging anything.
- **Touchpad.** It starts disabled — `hosts/thinkpad/i3` runs `touchpad off` on
  every restart. `~/Scripts/touchpad` (bound to `$mod+Shift+t`) turns it on, off,
  or flips it; `touchpad status` prints the current state. The tuning (tap to
  click, natural scrolling, two-finger scroll, clickfinger) is applied by the
  same script with `xinput`, so no file under `/etc` is needed. A resume from
  suspend can bring the device back enabled with libinput's defaults;
  `$mod+Shift+c` puts it right. The TrackPoint is untouched.
- **Keyboard.** `hosts/thinkpad` uses layout `br` with the `thinkpad` variant:
  on Brazilian ThinkPads the `/ ?` key sits where right Ctrl normally is. Click
  the layout block in the bar to switch to `us` (intl) and back. Under X a
  keyboard plugged in after login starts with the server defaults, so
  `~/Scripts/keyboard-watch` listens to udev and re-applies the repeat rate and
  the active layouts on every input hotplug.
- **Last upgrade.** The `last-updated` block reads `/var/log/pacman.log`, so it
  shows on Arch only and stays hidden elsewhere.
- **Default editor.** `common/xdg` ships an `nvim.desktop` that overrides the
  packaged one, which is `Terminal=true`. A bare window manager registers no
  terminal for `xdg-open` to resolve, so the override calls `kitty -e nvim`
  explicitly. Change the terminal there if you switch away from kitty.
- No secrets are tracked. `.gitignore` blocks SSH keys, shell history and
  browser profiles.
- **No licence, on purpose.** There is no `LICENSE` file, so default copyright
  applies: all rights reserved, nothing here is granted for reuse. Parts derive
  from [vyrx-dev/dotfiles](https://github.com/vyrx-dev/dotfiles) and
  `yazi/theme.toml` is theirs ("Symphony by vyrx"), so check their terms before
  lifting anything out of here.

## Dependencies

Install these first — this repo configures them, it does not install them.

**Window manager and desktop:** xorg-server, xorg-xauth (ly needs it for X
sessions), i3-wm (4.22 or newer, see [Portability](#portability)), i3blocks,
i3lock, xss-lock, dunst, rofi, feh, maim, xclip, xorg-xrandr, xorg-xinput,
xorg-setxkbmap, xorg-xset, xdg-desktop-portal-gtk

**Optional — each missing one costs only its feature:** picom (blur and dim),
autotiling, xbanish (hides the pointer while typing and after 8 s idle; AUR on
Arch, in the repositories on Debian/Ubuntu), arandr (finding a monitor layout)

**Deploying this repo:** stow, git

**Terminals and shell:** kitty, zsh, zsh-autosuggestions,
zsh-syntax-highlighting, zsh-completions, bat, eza

**Tools:** yazi, zathura, zathura-pdf-mupdf, btop, duf, brightnessctl,
pavucontrol

**Called by the bar, the keybindings and the scripts:** power-profiles-daemon,
pkgfile, playerctl (media keys), libpulse (`pactl`),
libnotify (`notify-send`), network-manager-applet (tray icon), nmgui (clicking
the network block), glib2 (`gsettings`), python (the statusline and
`dock-monitors`), qt6-base (the Qt/GTK theme bridge)

**Fonts:** inter-font, ttf-jetbrains-mono-nerd, ttf-dejavu (i3's tab and
stack titles), noto-fonts, noto-fonts-emoji

# dotfiles

i3 on X11, written to run on any distro. Configuration — how things look, and
how the tools used day to day behave. Developed on Arch; the baseline is
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
  picom/         compositor: dimmed unfocused windows, corners, animations (optional)
  kitty/         terminal
  yazi/          file manager theme
  zathura/       PDF reader
  gtk/           GTK 3 and 4: adw-gtk3, Papirus icons, Inter, palette colours
  theme/         the palette (theme.toml) and its templates — see Colours below
  fontconfig/    `sans-serif` is Inter, `monospace` JetBrains Mono
  flatpak/       global override: Flatpak apps may read the GTK theme files
  xdg/           default applications (browser, editor, PDF, folders)
  shell/         environment and aliases shared by both shells
  zsh/           zsh + oh-my-zsh + powerlevel10k
  bash/          bash fallback
  scripts/       powermenu, screenshot, volume, kbd-layout, keyboard-watch,
                 touchpad, power-profile-menu, lock, gsettings-sync,
                 theme-render, zen-chrome, osd, brightness —
                 deployed to ~/Scripts

hosts/thinkpad/
  i3/            keyboard layout, touchpad off at login, TrackPoint curve,
                 dock watcher
  scripts/       dock-monitors, trackpoint
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
- **Optional extras fail quietly.** picom, autotiling, xbanish and clipmenud
  are started so that a missing one costs only that feature.

## Notes

- **Symlinks that programs may replace.** Stow deploys files as symlinks, but a
  program that saves by writing a temp file and renaming it over the target
  destroys the link — silently, since the repo copy stays untouched and
  `git status` shows nothing. Known candidate here: `p10k configure`, which
  rewrites `~/.p10k.zsh`. After using it, re-run the `stow` commands from step 3
  with `--restow`.
- **`--no-folding`.** Pass it to every `stow` call. Without it, stow replaces a
  directory it is the sole owner of with a single symlink to the package —
  "tree folding". Both layers write into `~/Scripts`, so the second one then
  meets a folded symlink it does not own and aborts the whole run. Real
  directories holding one symlink per file cost nothing and let the layers
  stack.
- **`$mod+Shift+c` restarts i3** in place, keeping every window. Not a plain
  reload: i3 runs `exec_always` lines — touchpad off, keyboard
  settings — only on a restart, unlike sway, which ran them on reload.
- **Colours.** One palette, Kanagawa Dragon, in
  `common/theme/.config/theme/theme.toml`, with colours named by role (`bg`,
  `bg_alt`, `fg`, `accent`, ...). `~/Scripts/theme-render
  ~/.config/theme/theme.toml` fills the templates next to it and writes, through
  the stow symlinks, i3's window colours and bar (`i3/colors`), rofi, dunst
  (the whole `dunstrc`), kitty, GTK 3 and 4 (`gtk.css`), zathura, yazi, nvim
  (`lua/palette.lua`, fed to kanagawa.nvim under its own colour names), Zen
  Browser's `userChrome.css` and
  `theme/colors.sh` for the lock screen and the bar's warning colours. Then it
  reloads i3, dunst and kitty. The outputs are tracked, so a fresh checkout
  needs no render step; never edit them by hand. Needs Python 3.11+, only when
  changing the palette.
- **Zen Browser.** Profiles have random names, so the repo cannot link into
  one. Run `~/Scripts/zen-chrome` once per machine (and after creating a new
  profile): it links the generated `userChrome.css` into the default profile
  and enables the pref that makes Zen read it. Restart Zen. Only the interface
  changes; private windows keep Zen's own look.
- **Flatpak.** `flatpak/` holds a user-level global override that lets every
  Flatpak app read `gtk.css` (and the repo directory its symlink points into,
  which assumes the clone lives at `~/dotfiles`). The theme itself must also
  exist inside the sandbox: `flatpak install flathub org.gtk.Gtk3theme.adw-gtk3-dark`.
  `flatpak override --user` rewrites that file, replacing the link; restow
  afterwards.
- **GTK and Qt.** GTK 3 uses adw-gtk3 (the libadwaita look) and GTK 4
  libadwaita, both recoloured by `gtk.css`; without adw-gtk3, GTK 3 falls back
  to plain Adwaita dark. Qt programs follow GTK through the gtk3 platform
  theme.
  `~/Scripts/gsettings-sync` copies the GTK settings to gsettings on every i3
  restart, for libadwaita and Flatpak apps.
- **Geometry.** A 4 px scale: 8 px gaps, 8 px terminal padding, notifications
  8 px from the edge and below the bar, and 4 px corners on windows (picom),
  rofi and dunst. Two fonts: Inter for interface text, JetBrains Mono for
  monospace.
- **Background.** None: nothing draws on the root window, so X leaves it pure
  black (`#000000`) — pixels off on an OLED panel.
- **Idle and lock.** Lock at 5 minutes, screens off at 5.5, lock before
  suspend: `xset` sets the timers and xss-lock runs `~/Scripts/lock`. Lock by
  hand with `loginctl lock-session` (what the power menu does). With
  i3lock-color installed the lock shows a clock and a palette-coloured ring;
  plain i3lock gets the background colour, and so does i3lock-color if it ever
  rejects an option, so the screen always locks.
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
  `yazi/theme.toml` is based on theirs ("Symphony by vyrx"), so check their terms before
  lifting anything out of here.

## Dependencies

Install these first — this repo configures them, it does not install them.

**Window manager and desktop:** xorg-server, xorg-xauth (ly needs it for X
sessions), i3-wm (4.22 or newer, see [Portability](#portability)), i3blocks,
i3lock, xss-lock, dunst, rofi, maim, xclip, xorg-xrandr, xorg-xinput,
xorg-setxkbmap, xorg-xset, xdg-desktop-portal-gtk, polkit-gnome (password
prompts for programs that need admin rights; started by i3)

**Theme:** adw-gtk-theme, papirus-icon-theme

**Optional — each missing one costs only its feature:** i3lock-color (AUR on
Arch; replaces i3lock, adds the clock and ring), clipmenu (clipboard history,
`$mod+c`), rofi-emoji (emoji picker, `$mod+.`), picom (dim, corners, animations),
autotiling, xbanish (hides the pointer while typing and after 8 s idle; AUR on
Arch, in the repositories on Debian/Ubuntu), arandr (finding a monitor layout)

**Deploying this repo:** stow, git

**Terminals and shell:** kitty, zsh, zsh-autosuggestions,
zsh-syntax-highlighting, zsh-completions, bat, eza

**Tools:** yazi, zathura, zathura-pdf-mupdf, btop, duf, brightnessctl

**Terminal apps in place of GUI ones:** lazygit, lazydocker, fzf and zoxide
(hooked into zsh), fd, ripgrep, jq, glow, tealdeer (`tldr`), dua-cli (`dua`),
wiremix (mixer; clicking the volume block), bluetui (Bluetooth; clicking the
`bt` block, which reads bluez over D-Bus and needs the `bluetooth` service), spotify-player (needs Spotify Premium). Wi-Fi is
`nmtui`, part of NetworkManager. yazi is the default for folders.

**Called by the bar, the keybindings and the scripts:** power-profiles-daemon,
pkgfile, playerctl (media keys), libpulse (`pactl`),
libnotify (`notify-send`), networkmanager (`nmtui`, clicking the network
block), glib2 (`gsettings`), python (`dock-monitors`), qt6-base (the Qt/GTK theme bridge)

**Fonts:** inter-font, ttf-jetbrains-mono-nerd, noto-fonts, noto-fonts-emoji

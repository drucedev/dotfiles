# Dotfiles

## Theme

Everything runs Catppuccin Mocha, dark, with mauve (`#cba6f7`) as the accent —
no per-app themes, no light mode. fastfetch and other TUI apps without a theme
of their own inherit the palette from ghostty's ANSI overrides.

Touch points (a flavor switch touches exactly these):

| App | File | Carries color |
| --- | --- | --- |
| ghostty | `common/.config/ghostty/common.conf` | `theme =` |
| zed | `common/.config/zed/settings.json` | `theme`, `icon_theme` |
| nvim | `common/.config/nvim/lua/plugins/colorscheme.lua` | `flavour` |
| herdr | `common/.config/herdr/config.toml` | `theme.name` |
| btop | `common/.config/btop/btop.conf` | vendored theme file |
| quickshell | `linux/.config/quickshell/bar/Style.qml` | Mocha palette and bar dimensions |
| fuzzel | `linux/.config/fuzzel/catppuccin-mocha.ini` | `include=` in `fuzzel.ini` |
| swaylock | `linux/.config/swaylock/config` | whole file |
| niri | `linux/.config/niri/cfg/layout.kdl` | focus-ring colors |

Vendored files are verbatim from the official catppuccin ports — don't hand-edit
them. Future direction: a `theme` script here flips the fuzzel `include` to a
sibling flavor file and rewrites the Quickshell palette and remaining references.
Deliberately no home-manager; catppuccin/nix's home-manager modules were considered
and rejected for that reason.

GNU stow dotfiles for all machines, organized into per-scope packages:

| Machine | OS | Managed by | Stow packages |
| --- | --- | --- | --- |
| Odin (home Mac) | macOS | nix-darwin via [everything-nix](../everything-nix) | `common mac` |
| Thor (home PC) | NixOS | NixOS via everything-nix | `common linux` |
| Ivaldi (server) | NixOS | NixOS via everything-nix | `common linux` (optional) |

System-level config (packages, fonts, services) for the nix machines lives in
`~/everything-nix` — this repo only manages `$HOME` dotfiles.

## Layout

```
common/    stowed everywhere — zsh modules (~/.config/zsh), starship, ghostty,
           nvim, btop, fastfetch, zed, mise, pnpm, herdr, cliamp, gh
mac/       stowed on macOS — gnupg (pinentry-mac), zsh extras (darwin.zsh),
           reproducible launchers for terminal apps
linux/     stowed on Linux — niri, quickshell, desktop defaults (mimeapps,
           user-dirs), zsh extras (linux.zsh)
```

zsh has no native XDG support, so a two-line `~/.zshenv` bootstrap points
`ZDOTDIR` at `~/.config/zsh`; every other zsh file — `.zshrc`, modules and
all — lives there. `.zshrc` sources the shared modules, then the platform
extras and any optional `work.zsh` supplied by an external Stow package, so
the installed packages decide the machine's behavior.

## Requirements

Odin and Thor: `git`, `zsh`, `stow`. Ivaldi's user package set is deferred
until its server role is designed.

**Odin / Thor**: CLI tools (stow, starship, zoxide, fzf, lsd, ghostty,
mise, pnpm, …) are installed by everything-nix. Thor's Wayland desktop packages
(Quickshell, Fuzzel, and Swaylock) are installed by its NixOS configuration.
Ivaldi's package set is intentionally deferred. Two gaps to be aware of:

- `neovim` and `bat` are not in everything-nix yet; the nvim config here is
  inert and the `cat` alias degrades gracefully until you add them

## Git setup (per machine, intentionally not tracked)

`~/.gitconfig` is machine-local so each machine can use the appropriate
identity:

```sh
git config --global user.name "Andrei Kukharau"
git config --global user.email "contact@druce.dev"
git config --global init.defaultBranch main
```

## Install

Clone this repository to `~/.dotfiles`, then stow the packages for the machine:

```sh
git clone git@github.com:drucedev/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow --no-folding common mac   # adjust per machine, see table above
```

Agent configuration is installed separately from `~/Projects/self/agent-kit`:

```sh
cd ~/Projects/self/agent-kit
./scripts/install.sh all --profile personal
```

On macOS, install the Cliamp Spotlight/Finder launcher after stowing. This
creates a real app bundle in `~/Applications` and opens Cliamp in Ghostty:

```sh
install-macos-apps
```

Run the command again after changing its app metadata or launcher. Cliamp must
be available on the login shell's `PATH`, and Ghostty must be installed in
`/Applications`.

`--no-folding` makes stow create real directories and link only files, so
apps that write state into `~/.config/...` never write into this repo. Use
the same flag if you ever unstow (`stow -D --no-folding ...`).

## Quickshell (Linux)

The `bar` config is a lightweight, Omarchy Quattro-inspired status bar:
a 36px top bar on `DP-5`, Catppuccin Mocha at 92%
background opacity, and JetBrainsMono Nerd Font. It requires Quickshell 0.3.x
with Networking, PipeWire, and SystemTray support and Qt 6.8+ for windowed
popups (provided by NixOS here), NetworkManager's `nmcli`, and the existing Ghostty/btop and power-menu tools.

- Left: Niri workspaces from all outputs, ordered by output and workspace index;
  click to focus by stable ID. Named workspaces show a fixed icon; other workspaces
  show their number once created. The focused workspace is mauve.
- Center: English weekday and 24-hour time; left-click toggles to English date, ISO
  week, and year. No clock tooltip or calendar popup.
- Right: 16px tray icons, network, audio, CPU, and power. Tray icons support
  primary/middle activation, context menus (including submenus), and scrolling.
- Audio: left-click mutes output, right-click mutes the microphone, scroll changes
  output volume in 5% steps, capped at 100%. Muted output is red; hover shows volume.
- Network: wired/Wi-Fi/disconnected icon and signal strength, preferring connected
  wired devices when both are up. Hover fetches the interface's IP address.
- CPU: hover shows total/per-core usage sampled every five seconds without
  subprocesses; left-click opens `ghostty -e btop`.
- Power: left-click opens the existing Fuzzel `power-menu`; hover turns the icon red.

Niri uses a reconnecting event stream and a separate action socket. Audio,
network icons, and tray contents update through native services. The clock ticks
once a minute; `nmcli` runs only to fetch a hovered network tooltip. There is no
plugin framework, background command polling, or additional daemon.

From the repository root, stow the Linux package:

```sh
stow --no-folding -t "$HOME" linux
```

This links the config files into `~/.config/quickshell/bar/`. Niri starts
`qs --no-duplicate -c bar` at login through `cfg/autostart.kdl`. Config reloads
do not run startup commands; to start the bar in an existing session:

```sh
niri msg action spawn -- qs --no-duplicate -c bar
```

For a foreground development run, use `qs --no-duplicate -c bar` (Ctrl+C stops
that process), or `qs --no-duplicate -p linux/.config/quickshell/bar` without
stowing. The bar disappears when `DP-5` is disconnected and returns when it
reconnects.

The old Waybar config has been removed. On hosts where NixOS still enables its
user service, stop and mask it to prevent a second bar at login:

```sh
systemctl --user mask --now waybar.service
```

Disable Waybar declaratively in the NixOS project separately. After applying
that system configuration, remove the temporary user mask with
`systemctl --user unmask waybar.service`.

### Validation

Run both repository test suites:

```sh
node --test test/quickshell.test.cjs
./test/zsh.sh
```

The Quickshell suite needs Node.js and `qs`. It tests the production JavaScript,
loads the actual QML components and checks windowed tooltips offscreen, drives
Niri IPC through a temporary
Unix socket, and substitutes command executables to avoid changing audio,
launching applications, or invoking power actions. It does not stop Waybar or
change startup settings. Real device signals, popup placement/submenu rendering,
and monitor hotplug still need a live desktop check.

For static checks, run `node --check` on `BarLogic.js` and the test runner, and
`qmllint -W 0` on the config's QML files with the installed Qt and Quickshell QML
import directories supplied via `-I`, and `-i linux/.config/quickshell/bar/qmldir`.
The narrow lint exemptions document Quickshell's runtime-selected PanelWindow
backend and opaque ObjectModel metadata; the component tests exercise those
service models at runtime.

## Upgrading a machine from the monolithic layout

Machines stowed before the modular `~/.config/zsh` layout still carry
`~/.zshrc`, `~/.zprofile`, `~/.aliases` and possibly `~/.zshrc.darwin` or
`~/.zshrc.linux` as stow symlinks. After pulling this repo they dangle (the
package files are gone), and a dangling `~/.zshrc` would shadow nothing but
still clutter — remove them, restow, and clean up the stale pre-XDG history
file:

```sh
cd ~/.dotfiles && git pull
rm -f ~/.zshrc ~/.zprofile ~/.aliases ~/.zshrc.darwin ~/.zshrc.linux \
      ~/.zsh_history
stow --no-folding <packages>   # see table above
./test/zsh.sh                  # sandboxed, safe to run anywhere
```

Then open a new shell. zinit clones itself and its plugins on first run.
Verify the shell with `test/zsh.sh` — it builds a sandbox home, so it is
safe to run on any machine.

---

## Notes

- `fastfetch` expects an optional logo at `~/Pictures/logo.png`; missing file
  just means no logo.
- Ghostty keeps shared settings in `common/.config/ghostty/common.conf`; the
  macOS and Linux packages provide the platform wrapper. macOS starts Ghostty
  maximized, while Linux leaves window state to the compositor.
- The `uu` alias upgrades the whole machine and differs per package manager:
  nix-darwin rebuild on macOS and NixOS rebuild on Linux.

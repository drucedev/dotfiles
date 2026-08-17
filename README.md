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
| waybar | `linux/.config/waybar/mocha.css` | `@import` in `style.css` |
| fuzzel | `linux/.config/fuzzel/catppuccin-mocha.ini` | `include=` in `fuzzel.ini` |
| swaylock | `linux/.config/swaylock/config` | whole file |
| niri | `linux/.config/niri/cfg/layout.kdl` | focus-ring colors |

Vendored files are verbatim from the official catppuccin ports — don't hand-edit
them. Future direction: a `theme` script here flips the waybar `@import` and
fuzzel `include` to sibling flavor files and rewrites the few remaining
references. Deliberately no home-manager; catppuccin/nix's home-manager modules
were considered and rejected for that reason.

GNU stow dotfiles for all machines, organized into per-scope packages:

| Machine | OS | Managed by | Stow packages |
| --- | --- | --- | --- |
| Work Mac | macOS | Homebrew | `common mac work` |
| Odin (home Mac) | macOS | nix-darwin via [everything-nix](../everything-nix) | `common mac personal` |
| Thor (home PC) | NixOS | NixOS via everything-nix | `common linux personal` |
| Ivaldi (server) | NixOS | NixOS via everything-nix | `common linux personal` (optional) |

System-level config (packages, fonts, services) for the nix machines lives in
`~/everything-nix` — this repo only manages `$HOME` dotfiles.

## Layout

```
common/    stowed everywhere — zsh modules (~/.config/zsh), starship, ghostty,
           nvim, btop, fastfetch, wezterm, zed, pnpm, git ignore, herdr
mac/       stowed on both Macs — gnupg (pinentry-mac), zsh extras (darwin.zsh)
linux/     stowed on Linux — niri, zsh extras (linux.zsh)
personal/  stowed on non-work machines — personal pi agent-system
work/      stowed only on the work Mac — work pi agent-system, aws login,
           zsh extras (work.zsh)
```

zsh has no native XDG support, so a two-line `~/.zshenv` bootstrap points
`ZDOTDIR` at `~/.config/zsh`; every other zsh file — `.zshrc`, modules and
all — lives there. `.zshrc` sources the shared modules, then whichever of
`darwin.zsh`/`linux.zsh` and `work.zsh` the stowed packages provided, so the
packages decide the machine's behavior.

## Requirements

Odin and Thor: `git`, `zsh`, `stow`. Ivaldi's user package set is deferred
until its server role is designed.

**Work Mac** (brew):

```sh
brew install stow starship zoxide fzf lsd bat fnm awscli aws-sso-util awsume k9s
brew install --cask font-jetbrains-mono-nerd-font ghostty zed obsidian raycast docker-desktop
```

**Odin / Thor**: CLI tools (stow, starship, zoxide, fzf, lsd, ghostty,
pnpm, …) are installed by everything-nix. Thor's Wayland desktop packages
(Waybar, Fuzzel, and Swaylock) are installed by its host configuration.
Ivaldi's package set is intentionally deferred. Two gaps to be aware of:

- `neovim` and `bat` are not in everything-nix yet; the nvim config here is
  inert and the `cat` alias degrades gracefully until you add them

## Git setup (per machine, intentionally not tracked)

`~/.gitconfig` is machine-local so the work Mac can use a work identity:

```sh
git config --global user.name "Andrei Kukharau"
git config --global user.email "contact@druce.dev"   # use work email on the work Mac
git config --global init.defaultBranch main
```

## Install

Clone this repository to `~/.dotfiles`, then stow the packages for the machine:

```sh
git clone git@github.com:drucedev/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
stow --no-folding common mac work   # adjust per machine, see table above
```

`--no-folding` makes stow create real directories and link only files, so
apps that write state into `~/.config/...` never write into this repo. Use
the same flag if you ever unstow (`stow -D --no-folding ...`).

## Upgrading a machine from the monolithic layout

Machines stowed before the modular `~/.config/zsh` layout still carry
`~/.zshrc`, `~/.zprofile`, `~/.aliases` and possibly `~/.zshrc.darwin`,
`~/.zshrc.linux`, `~/.zshrc.work`, `~/.aws-login` as stow symlinks. After
pulling this repo they dangle (the package files are gone), and a dangling
`~/.zshrc` would shadow nothing but still clutter — remove them, restow,
and clean up the stale pre-XDG history file:

```sh
cd ~/.dotfiles && git pull
rm -f ~/.zshrc ~/.zprofile ~/.aliases ~/.zshrc.darwin ~/.zshrc.linux \
      ~/.zshrc.work ~/.aws-login ~/.zsh_history
stow --no-folding <packages>   # see table above
./test/zsh.sh                  # sandboxed, safe to run anywhere
```

Then open a new shell.

The work and personal Pi agent-system directories are self-contained because
Pi treats the real directory containing `definitions.json` as a trust boundary.
Keep the developer and jun/sen tier prose shared by both systems in sync.

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
  brew (work), nix-darwin rebuild (Macs), NixOS rebuild (Linux).

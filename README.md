# Dotfiles

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
common/    stowed everywhere — shell, starship, ghostty, nvim, btop,
           fastfetch, wezterm, zed, pnpm, git ignore, herdr
mac/       stowed on both Macs — gnupg (pinentry-mac), .zshrc.darwin
linux/     stowed on Linux — niri, .zshrc.linux
personal/  stowed on non-work machines — personal pi agent-system
work/      stowed only on the work Mac — work pi agent-system, aws login,
           .zshrc.work
```

The shell reads machine extras at the end of `.zshrc` — whichever of
`~/.zshrc.darwin`, `~/.zshrc.linux`, `~/.zshrc.work` exists gets sourced, so
the stowed packages decide the machine's behavior.

## Requirements

All machines: `git`, `zsh`, `stow`.

**Work Mac** (brew):

```sh
brew install stow starship zoxide fzf lsd bat fnm pipx awscli aws-sso-util awsume k9s
brew install --cask font-iosevka-term-nerd-font ghostty wezterm zed obsidian raycast docker-desktop
```

**Odin / Thor / Ivaldi**: CLI tools (stow, starship, zoxide, fzf, lsd,
ghostty, pnpm, …) are installed by everything-nix. Two gaps to be aware of:

- everything-nix currently ships only JetBrains Mono — add
  `nerd-fonts.iosevka-term` to `modules/fonts.nix` for the ghostty font
- `neovim` and `bat` are not in everything-nix yet; the nvim config here is
  inert and the `cat` alias degrades gracefully until you add them

## Git setup (per machine, intentionally not tracked)

`~/.gitconfig` is machine-local so the work Mac can use a work identity:

```sh
git config --global user.name "Andrei Kukharau"
git config --global user.email "contact@druce.dev"   # use work email on the work Mac
git config --global init.defaultBranch main
git config --global core.excludesFile ~/.config/git/ignore
```

## Install

```sh
git clone git@github.com:drucedev/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --no-folding common mac work   # adjust per machine, see table above
```

`--no-folding` makes stow create real directories and link only files, so
apps that write state into `~/.config/...` never write into this repo. Use
the same flag if you ever unstow (`stow -D --no-folding ...`).

The work and personal Pi agent-system directories are self-contained because
Pi treats the real directory containing `definitions.json` as a trust boundary.
Keep the developer and jun/sen tier prose shared by both systems in sync.

Then open a new shell. zinit clones itself and its plugins on first run.
Machine-local secrets go in `~/.secrets` (never tracked).

---

## Migration guide

### After the Pi agent-system split

Restow after pulling this layout so the moved Pi links are replaced:

```sh
stow --no-folding -R common mac work       # work Mac
stow --no-folding -R common mac personal   # home Mac
stow --no-folding -R common linux personal # Linux
```

### From an older dotfiles layout

Do the unstow + restow in one terminal session — already-open shells keep
working, but new shells have no config between the steps.

### From the old flat `dotfiles` layout (work Mac)

Old symlinks in `$HOME` point into the repo, so unstow **before** pulling:

```sh
cd ~/dotfiles        # wherever the old clone lives
stow -D .            # remove all old symlinks (old layout used folding — no flag)
git pull             # fetch the restructured layout
stow --no-folding common mac work
```

Afterwards:

1. **Prompt**: `brew install starship`; optionally `brew uninstall oh-my-posh`
   and `rm -rf ~/.config/ohmyposh`.
2. **Font**: ghostty now wants IosevkaTerm Nerd Font —
   `brew install --cask font-iosevka-term-nerd-font`.
3. **zsh history** moved to the XDG state dir (optional but recommended):
   `mkdir -p ~/.local/state/zsh && mv ~/.zsh_history ~/.local/state/zsh/history`
4. **zoxide** now replaces `cd` (`zoxide init --cmd cd`) — muscle memory
   still works, directories are learned as you go.
5. **git identity**: `~/.gitconfig` was never tracked by this repo, so it is
   untouched — nothing to do.

### From `dots` (Thor, while still on CachyOS)

```sh
cd ~/dots
stow -D .            # remove old symlinks — this also removes ~/.gitconfig!
```

`dots` tracked `~/.gitconfig`, so unstowing deletes the symlink. Recreate your
identity **before using git** (see *Git setup* above), then:

```sh
git clone git@github.com:drucedev/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow --no-folding common linux personal
```

Afterwards:

1. **bun** is no longer managed — remove it if you don't need it:
   `rm -rf ~/.bun` (also drop the bun lines from any leftover local rc files).
2. **zsh history** moved, same as above:
   `mkdir -p ~/.local/state/zsh && mv ~/.zsh_history ~/.local/state/zsh/history`
3. **niri and starship configs** come right back via the new packages —
   no action needed.
4. The old `dots` clone can be archived once everything works.

### When Thor is reinstalled as NixOS

CLI tools come from everything-nix. After the first boot:

```sh
git clone git@github.com:drucedev/dotfiles.git ~/dotfiles
cd ~/dotfiles && stow --no-folding common linux personal
```

### Odin (fresh, no prior dotfiles)

No migration — just *Requirements* → *Git setup* → *Install*, using
`stow --no-folding common mac personal`.

---

## Notes

- `fastfetch` expects an optional logo at `~/Pictures/logo.png`; missing file
  just means no logo.
- `maximize = true` in the ghostty config originates from the Mac config —
  if ghostty on Linux complains about it, that line can go per-machine.
- The `uu` alias upgrades the whole machine and differs per package manager:
  brew (work), nix-darwin rebuild (Macs), NixOS rebuild (Linux).

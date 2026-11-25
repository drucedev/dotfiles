# Dotfiles

GNU Stow dotfiles for `$HOME`. System packages, fonts, and services come from
[everything-nix](../everything-nix); this repo only links config files.

| Machine | OS | Stow packages |
| --- | --- | --- |
| Odin (home Mac) | macOS (nix-darwin) | `common mac` |
| Thor (home PC) | NixOS | `common linux` |
| Ivaldi (server) | NixOS | `common linux` (optional) |

- `common/` — everywhere: zsh, starship, ghostty, nvim, btop, fastfetch, zed,
  mise, pnpm, cliamp, gh, agent-settings templates, Pi theme
- `mac/` — macOS: gnupg, zsh extras, terminal-app launchers
- `linux/` — Linux: niri, fuzzel, swaylock, desktop defaults,
  session environment (environment.d), zsh extras

## Prerequisites

- The machine is built from everything-nix (provides `git`, `zsh`, `stow`, `direnv`, and the CLI tools).
- On Linux, the repo's flake devShell provides `stow` and `nodejs`; `git`, `zsh`, and
  `quickshell` stay global. `direnv allow` once to enter it on `cd`, or use
  `nix develop`. It is Linux-only because nixpkgs-unstable dropped x86_64-darwin, so
  macOS uses the system `stow`.
- SSH access to GitHub.
- A machine-local `~/.gitconfig` (intentionally not tracked):

  ```sh
  git config --global user.name "Andrei Kukharau"
  git config --global user.email "contact@druce.dev"
  git config --global init.defaultBranch main
  ```

## Install

```sh
git clone git@github.com:drucedev/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
direnv allow                     # Linux: enter the devShell (or: nix develop)
stow --no-folding common mac     # or: common linux — see the table above
```

Always pass `--no-folding` (also to `stow -D`): it links files, not
directories, so apps never write state into this repo. Don't use `stow --adopt`.

Then open a new shell; zinit installs itself and its plugins on first run.

## After install

- **Agents** — install instructions and skills from agent-kit, then apply
  shared preferences (stop Claude Code, Pi, and T3 Code first):

  ```sh
  cd ~/.agent-kit && ./scripts/install.sh all --profile personal
  apply-agent-settings all --dry-run
  apply-agent-settings all
  ```

  Details: [docs/agent-settings.md](docs/agent-settings.md).
- **macOS** — `install-macos-apps` creates the Cliamp launcher in `~/Applications`.
- **Linux** — install the [Bilskirnir](https://github.com/drucedev/bilskirnir)
  Quickshell bar (its README has the one-liner); Niri starts it at login. In a
  running session: `niri msg action spawn -- qs --no-duplicate -c bilskirnir`.
- **Optional** — put a logo at `~/Pictures/logo.png` for fastfetch.

Day to day, `uu` pulls everything-nix and rebuilds the machine.

## Check

On Linux, run these inside the devShell.

```sh
./test/zsh.sh                             # sandboxed shell test
node --test test/agent-settings.test.cjs  # temporary homes only
```

## More

- [docs/theme.md](docs/theme.md) — Catppuccin Mocha touch points
- [docs/zsh.md](docs/zsh.md) — zsh layout, upgrading old machines
- [docs/agent-settings.md](docs/agent-settings.md) — what `apply-agent-settings` does

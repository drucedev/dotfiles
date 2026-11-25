# Project notes

GNU Stow dotfiles. Top-level `common/`, `mac/`, and `linux/` are Stow packages
mirroring `$HOME`; `docs/`, `test/`, and these notes are not stowed.
Machine packages and system services belong in `~/everything-nix`, not here.
The exception is `flake.nix`: a Linux-only devShell (loaded by `.envrc`) holding
`stow` and `nodejs`; `git`, `zsh`, and `qs` stay global.

## Conventions

- Stow with `--no-folding` only; never `stow --adopt` on live agent settings.
- No home-manager.
- Catppuccin Mocha everywhere; color touch points are listed in `docs/theme.md`.
  Vendored catppuccin files stay verbatim — don't hand-edit them.
- zsh: `~/.zshenv` only bootstraps `ZDOTDIR`; zsh files live in
  `common/.config/zsh` plus platform extras (`docs/zsh.md`).
- Agent preference templates live in `common/.local/share/agent-settings/`;
  instructions, prompts, and skills belong to agent-kit (`docs/agent-settings.md`).

## Quickshell

The Quickshell bar lives in its own repo, Bilskirnir
(`~/.config/quickshell/bilskirnir`); this repo only starts it from
`linux/.config/niri/cfg/autostart.kdl`.

## Checks

On Linux, run inside the devShell (`nix develop` or direnv).

```sh
./test/zsh.sh
node --test test/agent-settings.test.cjs
```

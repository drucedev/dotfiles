# Project notes

GNU Stow dotfiles. Top-level `common/`, `mac/`, and `linux/` are Stow packages
mirroring `$HOME`; `docs/`, `test/`, and these notes are not stowed.
Packages and system services belong in `~/everything-nix`, not here.

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

This project's Quickshell bar is inspired by Omarchy Quattro. Behavior and
static checks: `docs/quickshell.md`.

## Checks

```sh
./test/zsh.sh
node --test test/agent-settings.test.cjs
node --test test/quickshell.test.cjs   # Linux, needs qs
```

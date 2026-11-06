# zsh

zsh has no native XDG support, so a two-line `~/.zshenv` bootstrap points
`ZDOTDIR` at `~/.config/zsh`; every other zsh file — `.zshrc`, modules and
all — lives there. `.zshrc` sources the shared modules, then the platform
extras (`darwin.zsh` or `linux.zsh`) and any optional `work.zsh` supplied by an
external Stow package, so the installed packages decide the machine's behavior.

The `uu` alias differs per platform: nix-darwin rebuild on macOS, NixOS rebuild
on Linux.

## Upgrading a machine from the monolithic layout

Machines stowed before the modular `~/.config/zsh` layout still carry
`~/.zshrc`, `~/.zprofile`, `~/.aliases` and possibly `~/.zshrc.darwin` or
`~/.zshrc.linux` as stow symlinks. After pulling this repo they dangle —
remove them, restow, and clean up the stale pre-XDG history file:

```sh
cd ~/.dotfiles && git pull
rm -f ~/.zshrc ~/.zprofile ~/.aliases ~/.zshrc.darwin ~/.zshrc.linux \
      ~/.zsh_history
stow --no-folding <packages>   # see the README table
./test/zsh.sh                  # sandboxed, safe to run anywhere
```

Then open a new shell. zinit clones itself and its plugins on first run.

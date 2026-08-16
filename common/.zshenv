# Bootstrap: zsh has no native XDG support, so this is the one zsh file that
# stays in $HOME — it redirects everything else into ~/.config/zsh.
# ZDOTDIR is hardcoded: stow installs these files at $HOME/.config/zsh
# regardless of the environment, and honoring a pre-set XDG_CONFIG_HOME
# would point ZDOTDIR at a directory with no .zshrc — a bare shell.
# zsh does not re-read .zshenv from $ZDOTDIR (verified on zsh 5.9), so the
# XDG exports must be sourced explicitly or they would never load.
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"

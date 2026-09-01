# Environment basics and PATH composition

# Default editor
export EDITOR=nvim
export VISUAL="$EDITOR"

# Paging
export PAGER=less
export MANPAGER='less -R'

# Set language environment
export LANG=en_US.UTF-8

# User-local binaries (pipx, manual installs)
export PATH="$PATH:$XDG_BIN_HOME"

# pnpm
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
mkdir -p "$PNPM_HOME/bin"
export PATH="$PNPM_HOME/bin:$PATH"

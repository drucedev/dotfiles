# Environment basics and PATH composition

# Set language environment
export LANG=en_US.UTF-8

# User-local binaries (pipx, manual installs)
export PATH="$PATH:$XDG_BIN_HOME"

# pnpm
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
mkdir -p "$PNPM_HOME/bin"
export PATH="$PNPM_HOME/bin:$PATH"

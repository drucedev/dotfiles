# XDG Base Directories — values match the spec defaults; exported explicitly
# so tool behavior is deterministic and other paths can compose from them.
# Lives in .zshenv (not .zprofile) because Linux terminals usually start
# non-login shells, and .zshenv is read by every zsh invocation.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_BIN_HOME="$HOME/.local/bin" # de facto standard (systemd), not in the formal spec

# proton-pass-cli: use the system keyring via Secret Service on Linux
[[ "$OSTYPE" == linux* ]] && export PROTON_PASS_LINUX_KEYRING=dbus

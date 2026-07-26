# Homebrew — only present on the work Mac; nix-managed machines skip this
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# User-local binaries (pipx, manual installs)
export PATH="$PATH:$XDG_BIN_HOME"

# proton-pass-cli: use the system keyring via Secret Service on Linux
[[ "$OSTYPE" == linux* ]] && export PROTON_PASS_LINUX_KEYRING=dbus

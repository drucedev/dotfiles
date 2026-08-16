#!/usr/bin/env bash
# Smoke test for the modular zsh config (XDG layout).
#
# Builds a sandbox home, stows the packages into it, and asserts the
# bootstrap chain end-to-end: ~/.zshenv sets ZDOTDIR, everything else loads
# from ~/.config/zsh. Safe to run on any machine — never touches $HOME
# (zinit is seeded into the sandbox so no network is needed).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REAL_HOME="$HOME"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
SANDBOX_HOME="$SANDBOX/home"
mkdir -p "$SANDBOX_HOME"

case "$(uname -s)" in
  Linux)  OS_PACKAGE=linux ;;
  Darwin) OS_PACKAGE=mac ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 2 ;;
esac

stow --no-folding -d "$REPO_ROOT" -t "$SANDBOX_HOME" common "$OS_PACKAGE"

# Seed zinit from the real home so plugin.zsh needs no network
if [ -d "$REAL_HOME/.local/share/zinit" ]; then
  mkdir -p "$SANDBOX_HOME/.local/share"
  cp -r "$REAL_HOME/.local/share/zinit" "$SANDBOX_HOME/.local/share/zinit"
fi

# The caller's shell exports XDG_*; a fresh login would not
sandbox_env=(env -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_STATE_HOME \
                -u XDG_CACHE_HOME -u XDG_BIN_HOME HOME="$SANDBOX_HOME")

# alias.zsh defines ll only when lsd exists — both states are correct
if command -v lsd >/dev/null; then want_ll="lsd -l"; else want_ll="MISSING"; fi

failures=0
check() { # check <description> <expected> <actual>
  if [[ "$2" == "$3" ]]; then
    echo "PASS: $1"
  else
    echo "FAIL: $1 — expected [$2] got [$3]" >&2
    failures=$((failures + 1))
  fi
}

# Non-interactive shells read only .zshenv — the bootstrap must set ZDOTDIR
# there and chain into $ZDOTDIR/.zshenv (proven by the XDG export)
nonint="$("${sandbox_env[@]}" zsh -c 'echo "$ZDOTDIR"; echo "$XDG_STATE_HOME"')"
check "non-interactive: ZDOTDIR points at ~/.config/zsh" \
      "$SANDBOX_HOME/.config/zsh" "$(echo "$nonint" | sed -n 1p)"
check "non-interactive: \$ZDOTDIR/.zshenv is chained (XDG_STATE_HOME)" \
      "$SANDBOX_HOME/.local/state" "$(echo "$nonint" | sed -n 2p)"

# Login shells read .zprofile from $ZDOTDIR — the bootstrap must run for
# them too (mac machines source homebrew there)
check "login: ZDOTDIR set before .zprofile" "$SANDBOX_HOME/.config/zsh" \
      "$("${sandbox_env[@]}" zsh -lc 'echo "$ZDOTDIR"')"

# A foreign XDG_CONFIG_HOME must not hijack the bootstrap: stow installs at
# ~/.config/zsh regardless, and composing ZDOTDIR from the env would leave
# the shell with no .zshrc at all
hijack="$(env -u XDG_DATA_HOME -u XDG_STATE_HOME -u XDG_CACHE_HOME \
            -u XDG_BIN_HOME XDG_CONFIG_HOME="$SANDBOX/bogus-xdg" \
            HOME="$SANDBOX_HOME" \
            zsh -ic 'echo "RESULT:zdot=$ZDOTDIR"; echo "RESULT:ll=${aliases[ll]:-MISSING}"' \
         2>/dev/null | sed -n 's/^RESULT://p')"
check "foreign XDG_CONFIG_HOME ignored for ZDOTDIR" "$SANDBOX_HOME/.config/zsh" \
      "$(echo "$hijack" | sed -n 's/^zdot=//p')"
check "foreign XDG_CONFIG_HOME: modules still load" "$want_ll" \
      "$(echo "$hijack" | sed -n 's/^ll=//p')"

# Interactive shell: full module chain + machine extras
inter="$("${sandbox_env[@]}" zsh -ic '
  echo "RESULT:ll=${aliases[ll]:-MISSING}"
  echo "RESULT:histfile=$HISTFILE"
  echo "RESULT:uu=${aliases[uu]:-MISSING}"
  echo "RESULT:workfn=$(( $+functions[pi-safe] ))"
  echo "RESULT:nixgc=$(( $+functions[nixgc] ))"
' 2>/dev/null | grep '^RESULT:')"

check "interactive: alias ll defined by alias.zsh" "$want_ll" \
      "$(echo "$inter" | sed -n 's/^RESULT:ll=//p')"
check "interactive: HISTFILE stays in state home" \
      "$SANDBOX_HOME/.local/state/zsh/history" \
      "$(echo "$inter" | sed -n 's/^RESULT:histfile=//p')"

uu="$(echo "$inter" | sed -n 's/^RESULT:uu=//p')"
case "$(uname -s)" in
  Linux)  want="nixos-rebuild" ;;   # linux.zsh
  Darwin) want="darwin-rebuild" ;; # darwin.zsh
esac
case "$uu" in
  *"$want"*) echo "PASS: interactive: $OS_PACKAGE extra sourced (uu → $want)" ;;
  *) echo "FAIL: interactive: machine extra — uu [$uu] lacks $want" >&2
     failures=$((failures + 1)) ;;
esac

check "interactive: work.zsh absent stays unsourced" "0" \
      "$(echo "$inter" | sed -n 's/^RESULT:workfn=//p')"

if (( failures )); then
  echo "$failures check(s) FAILED"
  exit 1
fi
echo "all checks passed"

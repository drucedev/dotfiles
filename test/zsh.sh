#!/usr/bin/env bash
# Smoke test for the modular zsh config (XDG layout).
#
# Builds a sandbox home, stows the packages into it, and checks the bootstrap
# chain: ~/.zshenv sets ZDOTDIR, everything else loads from ~/.config/zsh.
# Never touches $HOME (zinit is seeded into the sandbox so no network is needed).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
SANDBOX_HOME="$SANDBOX/home"
mkdir -p "$SANDBOX_HOME"

case "$(uname -s)" in
  Linux)  OS_PACKAGE=linux;  REBUILD=nixos-rebuild ;;
  Darwin) OS_PACKAGE=mac;    REBUILD=darwin-rebuild ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 2 ;;
esac

stow --no-folding -d "$REPO_ROOT" -t "$SANDBOX_HOME" common "$OS_PACKAGE"

if [ -d "$HOME/.local/share/zinit" ]; then
  mkdir -p "$SANDBOX_HOME/.local/share"
  cp -r "$HOME/.local/share/zinit" "$SANDBOX_HOME/.local/share/zinit"
fi

# The caller's shell exports XDG_* and ZDOTDIR; a fresh login would not.
sandbox_env=(env -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_STATE_HOME \
                -u XDG_CACHE_HOME -u XDG_BIN_HOME -u ZDOTDIR HOME="$SANDBOX_HOME")

# zval <zsh flags> <zsh expression>: the expression's value in a fresh sandboxed
# shell. A marker separates it from any startup noise; a failing shell prints
# a status that no check expects.
zval() {
  local out
  if out="$("${sandbox_env[@]}" zsh "$1" "print -r -- \"VALUE:$2\"" 2>/dev/null)"; then
    sed -n 's/^VALUE://p' <<< "$out"
  else
    echo "zsh exited $?"
  fi
}

failures=0
check() { # check <description> <expected> <actual>
  if [[ "$2" == "$3" ]]; then
    echo "PASS: $1"
  else
    echo "FAIL: $1 — expected [$2] got [$3]" >&2
    failures=$((failures + 1))
  fi
}

check "non-interactive shell sets ZDOTDIR" "$SANDBOX_HOME/.config/zsh" "$(zval -c '$ZDOTDIR')"
check "non-interactive shell chains \$ZDOTDIR/.zshenv" "$SANDBOX_HOME/.local/state" \
      "$(zval -c '$XDG_STATE_HOME')"
check "login shell sets ZDOTDIR" "$SANDBOX_HOME/.config/zsh" "$(zval -lc '$ZDOTDIR')"
check "interactive shell loads the alias module" 1 "$(zval -ic '$+aliases[v]')"
check "interactive shell keeps history in the state home" \
      "$SANDBOX_HOME/.local/state/zsh/history" "$(zval -ic '$HISTFILE')"
case "$(zval -ic '${aliases[uu]}')" in *"$REBUILD"*) extra=sourced ;; *) extra=missing ;; esac
check "interactive shell sources the $OS_PACKAGE extra" sourced "$extra"

# nixgc with stubs for sudo, nix-env and nix-collect-garbage. The nix-env stub
# logs argv with %q and lists 15 generations with 3 current, as after a rollback.
stubs="$SANDBOX/stubs"
calls="$SANDBOX/nixgc-calls.log"
mkdir "$stubs"
: > "$calls"
cat > "$stubs/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
cat > "$stubs/nix-env" <<'EOF'
#!/usr/bin/env bash
printf '[%q]' "$@" >> "$NIXGC_CALLS"; echo >> "$NIXGC_CALLS"
if [[ "$*" == *--list-generations* ]]; then
  for g in {1..15}; do
    current=""
    (( g == 3 )) && current="   (current)"
    printf '%4d   2026-01-%02d 12:00:00%s\n' "$g" "$g" "$current"
  done
fi
EOF
cat > "$stubs/nix-collect-garbage" <<'EOF'
#!/usr/bin/env bash
echo '[nix-collect-garbage]' >> "$NIXGC_CALLS"
EOF
chmod +x "$stubs"/*

# nixgc is defined only when nix-env is on PATH at startup.
"${sandbox_env[@]}" PATH="$stubs:$PATH" NIXGC_CALLS="$calls" \
  zsh -ic 'nixgc' >/dev/null 2>&1 || true

check "nixgc keeps 10 generations including the current one" \
      "[-p][/nix/var/nix/profiles/system][--delete-generations][1][2][4][5][6]" \
      "$(sed -n '/--delete-generations/p' "$calls")"
check "nixgc collects garbage after deleting" "[nix-collect-garbage]" "$(tail -n 1 "$calls")"

if (( failures )); then
  echo "$failures check(s) FAILED"
  exit 1
fi
echo "all checks passed"

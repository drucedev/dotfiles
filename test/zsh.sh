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

# The caller's shell exports XDG_* and ZDOTDIR; a fresh login would not
sandbox_env=(env -u XDG_CONFIG_HOME -u XDG_DATA_HOME -u XDG_STATE_HOME \
                -u XDG_CACHE_HOME -u XDG_BIN_HOME -u ZDOTDIR HOME="$SANDBOX_HOME")

# alias.zsh defines ll only when lsd exists — both states are correct
if command -v lsd >/dev/null; then want_ll="lsd -l"; else want_ll="MISSING"; fi

# tool.zsh registers amp's completion only when amp exists — both states are correct
if command -v amp >/dev/null; then want_amp="_amp"; else want_amp="MISSING"; fi

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
            -u XDG_BIN_HOME -u ZDOTDIR XDG_CONFIG_HOME="$SANDBOX/bogus-xdg" \
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
  echo "RESULT:ampcomp=${_comps[amp]:-MISSING}"
  echo "RESULT:uu=${aliases[uu]:-MISSING}"
  echo "RESULT:picm=${aliases[picm]:-MISSING}"
  echo "RESULT:workfn=$(( $+functions[aws-login] ))"
  echo "RESULT:nixgc=$(( $+functions[nixgc] ))"
' 2>/dev/null | grep '^RESULT:')"

check "interactive: alias ll defined by alias.zsh" "$want_ll" \
      "$(echo "$inter" | sed -n 's/^RESULT:ll=//p')"
check "interactive: HISTFILE stays in state home" \
      "$SANDBOX_HOME/.local/state/zsh/history" \
      "$(echo "$inter" | sed -n 's/^RESULT:histfile=//p')"
check "interactive: amp completion registered for amp" "$want_amp" \
      "$(echo "$inter" | sed -n 's/^RESULT:ampcomp=//p')"
check "interactive: picm alias starts pi with codemode" \
      "pi -ne -e builtin:codemode --tools +codemode" \
      "$(echo "$inter" | sed -n 's/^RESULT:picm=//p')"

# Registration alone is not enough: drive _amp directly, with compadd stubbed
# to print what it would offer for `amp th`
if command -v amp >/dev/null; then
  offers="$("${sandbox_env[@]}" zsh -ic '
    compset() { :; }
    compadd() { print -r -- "RESULT:$*"; }
    words=(amp th); CURRENT=2
    _amp
  ' 2>/dev/null | grep -cw threads || true)"
  check "amp completion offers subcommands (amp th → threads)" "1" "$offers"
fi

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

# nixgc must come from the shared modules, not the OS extra — Odin runs
# darwin.zsh (not linux.zsh) and still needs it. Simulate that by hiding the
# OS extra; also only assertable where the guard passes (nix present).
if command -v nix-env >/dev/null; then
  case "$OS_PACKAGE" in linux) extra=linux.zsh ;; mac) extra=darwin.zsh ;; esac
  os_extra="$SANDBOX_HOME/.config/zsh/$extra"
  mv "$os_extra" "$os_extra.hidden"
  check "nixgc defined without the OS extra (shared module)" "1" \
        "$("${sandbox_env[@]}" zsh -ic 'echo "RESULT:nixgc=$(( $+functions[nixgc] ))"' \
             2>/dev/null | sed -n 's/^RESULT:nixgc=//p')"
  mv "$os_extra.hidden" "$os_extra"
fi

# nixgc under zsh, with stubs ahead on PATH standing in for sudo, nix-env and
# nix-collect-garbage. The stubs log argv with %q, so an argument holding a
# newline shows as one $'...' token rather than as separate arguments.
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
  # 15 generations, 3 current as after a rollback: the 10 kept must include it
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

# nixgc is defined only when nix-env is on PATH at startup, so run it in an
# interactive shell. Effects are asserted from the call log, not the status.
"${sandbox_env[@]}" PATH="$stubs:$PATH" NIXGC_CALLS="$calls" \
  zsh -ic 'nixgc' >/dev/null 2>&1 || true

check "nixgc keeps 10 generations in total (current included), one argument each" \
      "[-p][/nix/var/nix/profiles/system][--delete-generations][1][2][4][5][6]" \
      "$(sed -n '/--delete-generations/p' "$calls")"
check "nixgc runs nix-collect-garbage after the deletes" \
      "[nix-collect-garbage]" "$(tail -n 1 "$calls")"

check "interactive: work.zsh absent stays unsourced" "0" \
      "$(echo "$inter" | sed -n 's/^RESULT:workfn=//p')"

if (( failures )); then
  echo "$failures check(s) FAILED"
  exit 1
fi
echo "all checks passed"

# Shell integrations — guarded so a missing tool never breaks a new shell
(( $+commands[fzf] )) && eval "$(fzf --zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init --cmd cd zsh)"
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  (( $+commands[starship] )) && eval "$(starship init zsh)"
fi

# Amp's completion script embeds a snapshot of its command tree and takes about
# 100 ms to generate, so it is generated on the first amp TAB rather than at
# shell start. Not cached on disk: amp self-updates, which would leave a stale
# snapshot. compdef needs compinit, which completion.zsh has already run.
if (( $+commands[amp] )); then
  _amp() {
    unfunction _amp
    eval "$(amp completions zsh)"
    _amp "$@"
  }
  compdef _amp amp
fi

# Collect nix garbage, keeping only 10 system generations in total, the
# current one included — shared by NixOS and nix-darwin (same system
# profile path on both).
# nix has no count-based delete, so build the delete set by hand: the
# single-pass awk skips the current one (nix-env refuses to delete it) and
# keeps the newest 9 of the rest. BSD head lacks negative -n counts, so awk
# does the windowing instead.
if (( $+commands[nix-env] )); then
  nixgc() {
    local gens
    gens=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations \
           | awk '/current/ { next } { g[++n]=$1 } END { for (i=1; i<=n-9; i++) print g[i] }')
    [ -n "$gens" ] && sudo nix-env -p /nix/var/nix/profiles/system --delete-generations ${=gens}
    sudo nix-collect-garbage
  }
fi

# Shell integrations — guarded so a missing tool never breaks a new shell
(( $+commands[fzf] )) && eval "$(fzf --zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init --cmd cd zsh)"
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  (( $+commands[starship] )) && eval "$(starship init zsh)"
fi

# Collect nix garbage, keeping only the 10 newest system generations —
# shared by NixOS and nix-darwin (same system profile path on both).
# nix has no count-based delete, so build the delete set by hand: the
# single-pass awk keeps everything but the newest 10 generation numbers
# and excludes the current one (nix-env refuses to delete it; BSD head
# lacks negative -n counts, so awk does the windowing instead).
if (( $+commands[nix-env] )); then
  nixgc() {
    local gens
    gens=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations \
           | awk '/current/ { next } { g[++n]=$1 } END { for (i=1; i<=n-10; i++) print g[i] }')
    [ -n "$gens" ] && sudo nix-env -p /nix/var/nix/profiles/system --delete-generations $gens
    sudo nix-collect-garbage
  }
fi

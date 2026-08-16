# Shell integrations — guarded so a missing tool never breaks a new shell
(( $+commands[fzf] )) && eval "$(fzf --zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init --cmd cd zsh)"
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  (( $+commands[starship] )) && eval "$(starship init zsh)"
fi


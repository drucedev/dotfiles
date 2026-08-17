# Work-Mac-only extras. Sourced after darwin.zsh, so anything here
# overrides the mac package defaults.

# Node version manager
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell zsh)"

# Full system upgrade — this machine is managed by brew, not nix
alias uu="bubu; npm outdated -g --depth=0; npm update -g"

# AWSume alias to source the AWSume script
alias awsume="source awsume"

# Auto-Complete function for AWSume
fpath=($XDG_CONFIG_HOME/awsume/zsh-autocomplete/ $fpath)

# Homebrew cleanup policy
export HOMEBREW_CLEANUP_MAX_AGE_DAYS=30

# Work-only zsh plugins (tools installed via brew/sdkman on this machine)
zinit snippet OMZP::brew
zinit snippet OMZP::gradle
zinit snippet OMZP::kubectl
zinit snippet OMZP::sdk

# These snippets load after the compinit/cdreplay in completion.zsh —
# replay so their compdef calls (gradle, sdk) actually register
zinit cdreplay -q

# Completions for work CLIs
(( $+commands[codex] )) && eval "$(codex completion zsh)"
(( $+commands[acli] )) && source <(acli completion zsh)

# AWS login helpers (folded in from the old ~/.aws-login)
function aws-login() {
    aws-sso-util login
    awsume-choice
}

function awsume-choice() {
    choice="$(FZF_DEFAULT_COMMAND='awsume -l' fzf --ansi)"
    choice="$(echo "$choice" | awk '{ print $1 }')"
    awsume $choice
}

# Sandboxed pi launcher
pi-safe() {
  local args=(
    --no-private-home
    --rw-map /Users

    --deny-path "$HOME/.aws"
    --deny-path "$HOME/.cdk"
    --deny-path "$HOME/.cisco"
    --deny-path "$HOME/.docker"
    --deny-path "$HOME/.gnupg"
    --deny-path "$HOME/.kube"
    --deny-path "$HOME/.ssh"
    --deny-path "$HOME/.terraform.d"
    --deny-path "$HOME/.vpn"
    --deny-path "$HOME/Desktop"
    --deny-path "$HOME/Downloads"
    --deny-path "$HOME/Library"
    --deny-path "$HOME/Movies"
    --deny-path "$HOME/Music"
    --deny-path "$HOME/Pictures"

    --no-save-config
    --exec
  )

  ai-jail "${args[@]}" -- pi "$@"
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

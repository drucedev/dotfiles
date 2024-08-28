# Autocompletion in zsh for brew
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

# NVM plugin config
NVM_HOMEBREW=$(brew --prefix nvm)

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Aws Login
[[ -f ~/.aws-login ]] && source ~/.aws-login

# kubectl autocomplite
source <(kubectl completion zsh)

# Secrets
[[ -f ~/.secrets ]] && source ~/.secrets

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm

# Homebrew Config
HOMEBREW_CLEANUP_MAX_AGE_DAYS=30

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

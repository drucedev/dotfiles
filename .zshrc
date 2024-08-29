# Directory for storing zinit and it's plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if it's not there
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Auto load completions
autoload -U compinit && compinit

# History
HISTSIZE=5000
HISTFILE=$HOME/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases

# Aws Login
[[ -f ~/.aws-login ]] && source ~/.aws-login

# Secrets
[[ -f ~/.secrets ]] && source ~/.secrets

# NVM plugin config
NVM_HOMEBREW=$(brew --prefix nvm)
export NVM_DIR="$HOME/.nvm"
# This loads nvm
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
# This loads nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 

# Homebrew Config
HOMEBREW_CLEANUP_MAX_AGE_DAYS=30

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Set language environment
export LANG=en_US.UTF-8

# User-local binaries (pipx, manual installs)
export PATH="$PATH:$XDG_BIN_HOME"

# Directory for storing zinit and its plugins
ZINIT_HOME="$XDG_DATA_HOME/zinit/zinit.git"

# Download zinit if it's not there
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

# Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::git

# Extra completion definitions
fpath=(~/.zfunc $fpath)

# zsh does not create missing parent dirs for HISTFILE/compdump
[[ -d $XDG_STATE_HOME/zsh ]] || mkdir -p "$XDG_STATE_HOME/zsh"
[[ -d $XDG_CACHE_HOME/zsh ]] || mkdir -p "$XDG_CACHE_HOME/zsh"

# Auto load completions
autoload -U compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zinit cdreplay -q

# Shell integrations — guarded so a missing tool never breaks a new shell
(( $+commands[fzf] )) && eval "$(fzf --zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init --cmd cd zsh)"
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell zsh)"
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  (( $+commands[starship] )) && eval "$(starship init zsh)"
fi

# History
HISTSIZE=5000
HISTFILE="$XDG_STATE_HOME/zsh/history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# pnpm
export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
mkdir -p "$PNPM_HOME/bin"
export PATH="$PNPM_HOME/bin:$PATH"

# Dependencies
# Aliases
[[ -f ~/.aliases ]] && source ~/.aliases
# Secrets (never tracked)
[[ -f ~/.secrets ]] && source ~/.secrets

# Machine-specific extras provided by stow packages (mac/linux/work);
# sourced last so they can override anything above
for extra in ~/.zshrc.${(L)$(uname -s)} ~/.zshrc.work; do
  [[ -f $extra ]] && source "$extra"
done

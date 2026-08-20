# Aliases shared by all machines. Machine-specific aliases live in
# $ZDOTDIR/linux.zsh / darwin.zsh, with optional profile aliases supplied by
# external Stow packages.
# The general format of an alias is as follows
#	alias short_cut_name='commands to carry out'

# We're using lsd! The colors!
if [ -x "$(command -v lsd)" ]; then
    alias ls='lsd'
    alias ll='lsd -l'
    alias la='lsd -la'
fi

# bat instead of cat
if [ -x "$(command -v bat)" ]; then
    alias cat='bat'
fi

# Show sorted used memory of folders
alias used='du -sch * | sort -rh'

# File: ~/.bash_aliases
# Info: A list of useful user-defined shortcuts
# Add this file to ~/.bashrc or ~/.zshrc
#	[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases
# Use this file to add alias commands that should work in Bash and/or Zsh.
# Multiline commands should be defined as functions, preferibly in a script (in ~/bin) that can be referenced here.
# The general format of an alias is as follows
#	alias short_cut_name='commands to carry out'

# We're using lsd! The colors!
if [ -x "$(command -v lsd)" ]; then
    alias ls='lsd'
    alias ll='lsd -l'
    alias la='lsd -la'
fi

# Show sorted used memory of folders
alias used='du -sch * | sort -rh'

# Go to EP2-Core folder
alias ep2='cd ~/Projects/hypoport/ep2-core'

# Open Firefox Profile Manager
alias foxprofile='/Applications/Firefox.app/Contents/MacOS/firefox-bin -P'

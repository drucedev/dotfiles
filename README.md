## Dotfiles

This project contains the dotfiles of my work MacOS systems

### Requirements

 - Git (To install open Terminal and type `git`)
 - Brew (To install go to brew.sh and copy command. Note: **sudo is required**)
 - sdkman (To install go to sdkman.io and copy command.)
 - SSH key (Follow instructions from https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

 ### List of packages to install

```shell
brew install stow zoxide oh-my-posh fzf lsd bat awscli aws-sso-util awsume k9s
```

### List of casks to install

```shell
brew install --cask font-jetbrains-mono-nerd-font obsidian raycast wezterm zed
```

### Installation

```shell
git clone git@github.com:drucedev/dotfiles.git
cd dotfiles

stow .
```

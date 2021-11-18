#!/bin/sh

# Download Item2

# Ssh
ssh -T git@github.com


# Install HomeBrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install ZSH
brew install zsh

# ZSH to be the default
sudo sh -c "echo $(which zsh) >> /etc/shells" && chsh -s $(which zsh)

# Get the config
git clone https://github.com/satnami/dotfiles ~/dotfiles

# Setup dotfiles
sh ~/dotfiles/dot_import.sh
 
# Setup OhmyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Setup OhMyZSH Theme
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

# Setup OhMyZSH plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone git@github.com:marzocchi/zsh-notify.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/notify

# Setup Iterm itegrations
cd ~/.
curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash

# Setup Up
curl --create-dirs -o ~/.config/up/up.sh https://raw.githubusercontent.com/shannonmoeller/up/master/up.sh

# Setup Zplug
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

# Setup Brew
cd ~/dotfiles/Mac
brew bundle

# Setup default local Gems
git clone https://github.com/rbenv/rbenv-default-gems.git $(rbenv root)/plugins/rbenv-default-gems
cp ~/dotfiles/packages/gems.list $(rbenv root)/default-gems

# Setup Ruby
rbenv install 3.0.2
rbenv global 3.0.2
ruby -v
#!/bin/sh

# Download Item2

# SSH
ssh -T git@github.com

# HomeBrew
if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi


# ZSH
if ! command -v zsh >/dev/null 2>&1; then
    brew install zsh
    sudo sh -c "echo $(which zsh) >> /etc/shells" && chsh -s $(which zsh)
fi

# Get the config
git clone https://github.com/satnami/dotfiles ~/dotfiles

# Setup dotfiles
sh ~/dotfiles/dot_import.sh

#  OhmyZSH
# Setup OhmyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Setup OhMyZSH Theme
#git clone https://github.com/bhilburn/powerlevel9k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel9k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# Setup OhMyZSH plugins
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
#git clone git@github.com:marzocchi/zsh-notify.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/notify

# Setup Iterm itegrations
cd ~/.
curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash

# Setup Up
curl --create-dirs -o ~/.config/up/up.sh https://raw.githubusercontent.com/shannonmoeller/up/master/up.sh

# Setup Fonts
git clone https://github.com/powerline/fonts.git ~/powerline-fonts
cd ~/powerline-fonts
./install

# Setup Brew
cd ~/dotfiles/Brew
brew bundle

# Setup SDKMAN
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Setup Vim
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
vim +PluginUpdate +qall

# Ruby
# Setup Ruby default gems
git clone https://github.com/rbenv/rbenv-default-gems.git $(rbenv root)/plugins/rbenv-default-gems
cp ~/dotfiles/packages/gems.list $(rbenv root)/default-gems
# Setup Ruby
rbenv install 3.0.2
rbenv global 3.0.2
ruby -v

# Node
# Setup Node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
nvm install 20
nvm use node
# Setup Npm libraries
sh ~/dotfiles/packages/npm.list

:'
# Erlang
# Setup Erlang
brew install autoconf@2.69
brew link --overwrite autoconf@2.69
kerl update
kerl build 22.3 22.3
kerl install 22.3 ~/kerl/default
source ~/kerl/default/activate
brew install rebar3
# Setup Erlang Language Server
git clone https://github.com/erlang-ls/erlang_ls ~/kerl/erlang-ls
cd ~/kerl/erlang-ls
make
_build/default/bin/erlang_ls /usr/local/bin
# Setup Erlang Style
git clone https://github.com/inaka/elvis ~/kerl/elvis
cd ~/kerl/elvis
rebar3 compile
rebar3 escriptize
cp _build/default/bin/elvis /usr/local/bin
'

# Setup crontab for history backup
(crontab -l && echo "0 12 * * * ~/dotfiles/cron/history_backup") | crontab -

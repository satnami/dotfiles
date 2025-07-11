#!/bin/sh

set -euo pipefail

echo "?? Starting setup"

CI_MODE="${CI_MODE:-false}"
# Enable CI mode if environment variable CI is set by the system
if [ "${CI:-}" = "true" ]; then
  CI_MODE=true
fi
echo "?? CI mode: $CI_MODE"

# ----------------------------------------
# Log to timestamped file + stdout
# ----------------------------------------
if [ "$CI_MODE" = "false" ]; then
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  LOGFILE="$HOME/setup_$TIMESTAMP.log"
  exec > >(tee -a "$LOGFILE") 2>&1
  echo "?? Log: $LOGFILE"
  echo "?? Started at $(date)"
  echo "----------------------------------------"
else
  echo "?? Running in CI mode"
  LOGFILE="$HOME/setup_ci.log"
  exec >"$LOGFILE" 2>&1
  echo "?? CI Log: $LOGFILE"
  echo "?? Started at $(date)"
  echo "----------------------------------------"
  trap 'cat "$LOGFILE"' EXIT
fi

# ----------------------------------------
# macOS check
# ----------------------------------------
if [ "$(uname)" != "Darwin" ]; then
  echo "? This script is macOS-only."
  exit 1
fi

# ----------------------------------------
# Alias pushd/popd (quiet)
# ----------------------------------------
alias pushd='pushd > /dev/null'
alias popd='popd > /dev/null'

# ----------------------------------------
# SSH check
# ----------------------------------------
ssh -T git@github.com || echo "?? SSH authentication failed"

# ----------------------------------------
# Homebrew
# ----------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "?? Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "? Homebrew already installed"
fi

# ----------------------------------------
# Zsh
# ----------------------------------------
if ! command -v zsh >/dev/null 2>&1; then
  brew install zsh
  ZSH_PATH="$(which zsh)"
  if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
  fi
  chsh -s "$ZSH_PATH"
else
  echo "? Zsh already installed"
fi

# ----------------------------------------
# Dotfiles
# ----------------------------------------
if [ "$CI_MODE" = "false" ]; then
  if [ ! -d "$HOME/dotfiles" ]; then
    git clone https://github.com/satnami/dotfiles ~/dotfiles
  else
    echo "?? dotfiles already installed"
  fi

  sh ~/dotfiles/dot_import.sh
else
  echo "?? Skipping dotfiles installation in CI mode"
fi

# ----------------------------------------
# Oh My Zsh
# ----------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "? Oh My Zsh already installed"
fi

# ----------------------------------------
# Powerlevel10k Theme
# ----------------------------------------
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# ----------------------------------------
# Zsh Plugins
# ----------------------------------------
PLUG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
[ ! -d "$PLUG_DIR/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUG_DIR/zsh-syntax-highlighting"
[ ! -d "$PLUG_DIR/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUG_DIR/zsh-autosuggestions"
# Optional: zsh-notify plugin (commented out)
# git clone git@github.com:marzocchi/zsh-notify.git "$PLUG_DIR/notify"

# ----------------------------------------
# iTerm Integration
# ----------------------------------------
curl -L https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash

# ----------------------------------------
# Up.sh
# ----------------------------------------
UP_PATH="$HOME/.config/up/up.sh"
if [ ! -f "$UP_PATH" ]; then
  curl --create-dirs -o "$UP_PATH" https://raw.githubusercontent.com/shannonmoeller/up/master/up.sh
  [ -f "$UP_PATH" ] && chmod +x "$UP_PATH" && echo "? up.sh installed"
else
  echo "?? up.sh already exists"
fi

# ----------------------------------------
# zplug
# ----------------------------------------
if [ ! -d "$HOME/.zplug" ]; then
  curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
  [ -d "$HOME/.zplug" ] && echo "? zplug installed"
else
  echo "?? zplug already installed"
fi

if ! grep -q 'zplug/init.zsh' "$HOME/.zshrc"; then
  echo "# zplug init" >> "$HOME/.zshrc"
  echo "source ~/.zplug/init.zsh" >> "$HOME/.zshrc"
  echo "zplug load" >> "$HOME/.zshrc"
fi

# ----------------------------------------
# Fonts
# ----------------------------------------
if [ ! -d "$HOME/powerline-fonts" ]; then
  git clone https://github.com/powerline/fonts.git ~/powerline-fonts
  pushd ~/powerline-fonts || exit
  ./install
  popd
else
  echo "?? Fonts already installed"
fi

# ----------------------------------------
# Brewfile
# ----------------------------------------
pushd ~/dotfiles/Brew || exit
brew bundle
popd

# ----------------------------------------
# SDKMAN
# ----------------------------------------
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# ----------------------------------------
# Vim with Vundle
# ----------------------------------------
if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

vim +PluginInstall +qall
vim +PluginUpdate +qall

# ----------------------------------------
# Ruby via rbenv
# ----------------------------------------
if ! command -v rbenv >/dev/null 2>&1; then
  brew install rbenv ruby-build
  eval "$(rbenv init -)"
fi

if command -v rbenv >/dev/null 2>&1; then
  if [ ! -d "$(rbenv root)/plugins/rbenv-default-gems" ]; then
    git clone https://github.com/rbenv/rbenv-default-gems.git "$(rbenv root)/plugins/rbenv-default-gems"
  fi
  cp ~/dotfiles/packages/gems.list "$(rbenv root)/default-gems"
  rbenv install -s 3.0.2
  rbenv global 3.0.2
  ruby -v
fi

# ----------------------------------------
# Node via NVM
# ----------------------------------------
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 20
nvm use node
sh ~/dotfiles/packages/npm.list

# ----------------------------------------
# Erlang (Optional, Commented)
# ----------------------------------------
: '
# Erlang + Erlang LS + Elvis Style Checker

# Install build tools
brew install autoconf@2.69 rebar3 kerl

# Link autoconf for compatibility
brew link --overwrite autoconf@2.69

# Build and install Erlang with kerl
kerl update releases
kerl build 22.3 22.3
kerl install 22.3 ~/kerl/default
source ~/kerl/default/activate

# Install Erlang Language Server
git clone https://github.com/erlang-ls/erlang_ls.git ~/kerl/erlang-ls
pushd ~/kerl/erlang-ls
make
cp _build/default/bin/erlang_ls /usr/local/bin
popd

# Install Elvis (Erlang style linter)
git clone https://github.com/inaka/elvis.git ~/kerl/elvis
pushd ~/kerl/elvis
rebar3 compile
rebar3 escriptize
cp _build/default/bin/elvis /usr/local/bin
popd
'

# ----------------------------------------
# Crontab for history backup
# ----------------------------------------
(crontab -l 2>/dev/null; echo "0 12 * * * ~/dotfiles/cron/history_backup") | crontab -

# ----------------------------------------
# Done
# ----------------------------------------
echo "? Setup complete at $(date)"
echo "?? Log file saved to: $LOGFILE"
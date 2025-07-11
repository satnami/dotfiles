#!/bin/sh

set -euo pipefail

CI_MODE="${CI_MODE:-false}"
# Enable CI mode if environment variable CI is set by the system
if [ "${CI:-}" = "true" ] || [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  CI_MODE=true
fi

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
  # In CI, we want output to go to both stdout and log file
  exec > >(tee -a "$LOGFILE") 2>&1
  echo "?? CI Log: $LOGFILE"
  echo "?? Started at $(date)"
  echo "----------------------------------------"
  # Don't use set -x in CI as it interferes with echo output
  # set -x
fi

echo "?? Starting setup"

echo "?? CI mode: $CI_MODE"
echo "?? CI env var: ${CI:-not_set}"
echo "?? GITHUB_ACTIONS: ${GITHUB_ACTIONS:-not_set}"
echo "?? PWD: $PWD"
echo "?? HOME: $HOME"

# ----------------------------------------
# macOS check
# ----------------------------------------
if [ "$(uname)" != "Darwin" ]; then
  echo "? This script is macOS-only."
  exit 1
fi

# ----------------------------------------
# Alias pushd/popd (quiet in non-CI mode)
# ----------------------------------------
if [ "$CI_MODE" = "false" ]; then
  alias pushd='pushd > /dev/null'
  alias popd='popd > /dev/null'
else
  # In CI mode, keep pushd/popd output visible
  alias pushd='pushd'
  alias popd='popd'
fi

# ----------------------------------------
# SSH check (skip in CI)
# ----------------------------------------
if [ "$CI_MODE" = "false" ]; then
  ssh -T git@github.com || echo "?? SSH authentication failed"
else
  echo "?? Skipping SSH check in CI mode"
fi

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
  if [ "$CI_MODE" = "false" ]; then
    chsh -s "$ZSH_PATH"
  else
    echo "?? Skipping shell change in CI mode"
  fi
else
  echo "? Zsh already installed"
fi

# ----------------------------------------
# Dotfiles
# ----------------------------------------
if [ "$CI_MODE" = "true" ]; then
  echo "? Repo already checked out by GitHub Actions"
  DOTFILES_DIR="$PWD"
  # Verify we're in the right directory
  if [ ! -f "$DOTFILES_DIR/dot_import.sh" ]; then
    echo "? ERROR: dot_import.sh not found in $DOTFILES_DIR"
    echo "? Expected to be in dotfiles directory but files are missing"
    exit 1
  fi
else
  DOTFILES_DIR="$HOME/dotfiles"
  if [ ! -d "$DOTFILES_DIR" ]; then
    git clone https://github.com/satnami/dotfiles "$DOTFILES_DIR"
  else
    echo "?? dotfiles already installed"
  fi
  
  # Only run dot_import.sh if the expected dotfiles exist
  if [ -f ~/dotfiles/.zshrc ] && [ -f ~/dotfiles/.vimrc ]; then
    sh ~/dotfiles/dot_import.sh
  else
    echo "?? Some dotfiles are missing, skipping import"
  fi
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
# git clone https://github.com/marzocchi/zsh-notify.git "$PLUG_DIR/notify"

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
FONTS_DIR="$HOME/powerline-fonts"
if [ ! -d "$FONTS_DIR" ]; then
  git clone https://github.com/powerline/fonts.git "$FONTS_DIR"
fi

if [ -f "$FONTS_DIR/install" ]; then
  pushd "$FONTS_DIR"
  ./install
  popd
else
  echo "? Font installer not found in $FONTS_DIR — skipping"
fi

# ----------------------------------------
# Brewfile
# ----------------------------------------
if [ "$CI_MODE" = "false" ]; then
  pushd ~/dotfiles/Brew || exit
  brew bundle
  popd
fi

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

if [ "$CI_MODE" = "false" ]; then
  vim +PluginInstall +qall
  vim +PluginUpdate +qall
else
  echo "?? Skipping vim plugin setup in CI mode"
fi

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
# Crontab for history backup (skip in CI)
# ----------------------------------------
if [ "$CI_MODE" = "false" ]; then
  (crontab -l 2>/dev/null; echo "0 12 * * * ~/dotfiles/cron/history_backup") | crontab -
else
  echo "?? Skipping crontab setup in CI mode"
fi

# ----------------------------------------
# Done
# ----------------------------------------
echo "? Setup complete at $(date)"
if [ "$CI_MODE" = "true" ]; then
  echo "?? CI Log file saved to: $LOGFILE"
else
  echo "?? Log file saved to: $LOGFILE"
fi
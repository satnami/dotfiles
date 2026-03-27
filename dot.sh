#!/usr/bin/env bash

# Unified dotfile management: import, backup, and diff
# Usage: dot.sh <import|backup|diff>

DOTFILES_DIR="$HOME/dotfiles"
LOCATIONS="aliases bash_profile editorconfig exports functions gemrc gitconfig gitignore_global hushlogin psqlrc vimrc zshrc kerlrc history_preexec.sh p9k.zsh p10k.zsh"

dot_import() {
  local NOW=$(date +"%Y_%m_%d_%H_%M_%S")
  for location in $LOCATIONS; do
    [ -f ~/.$location ] && cp ~/.$location ~/.$location.$NOW.backup
    [ -f "$DOTFILES_DIR/.$location" ] && cp "$DOTFILES_DIR/.$location" ~/.$location
  done
  echo "Dotfiles imported (backups timestamped $NOW)"
}

dot_backup() {
  for location in $LOCATIONS; do
    [ -f ~/.$location ] && cp ~/.$location "$DOTFILES_DIR/.$location"
  done
  echo "Dotfiles backed up to $DOTFILES_DIR"
}

dot_diff() {
  for location in $LOCATIONS; do
    if [ -f "$DOTFILES_DIR/.$location" ] && [ -f ~/.$location ]; then
      diff --color "$DOTFILES_DIR/.$location" ~/.$location --unified=0
    fi
  done
}

case "${1:-}" in
  import)  dot_import ;;
  backup)  dot_backup ;;
  diff)    dot_diff ;;
  *)
    echo "Usage: dot.sh <import|backup|diff>"
    echo ""
    echo "  import  - Copy repo dotfiles to ~/ (creates timestamped backups)"
    echo "  backup  - Copy ~/ dotfiles into the repo"
    echo "  diff    - Show differences between repo and ~/"
    exit 1
    ;;
esac

#!/bin/bash

# Create a directory for the Ghostty config file
mkdir -p ~/.config/ghostty

# Create a symlink to the actual config file
ln -sf "$HOME/.config/ghostty/config" "$HOME/dotfiles/ghostty/config"

ln -sf "$HOME/Library/Application Support/com.mitchellh.ghostty/config" "$HOME/dotfiles/ghostty/config"
 
# Check the symlink
ls -l $HOME/dotfiles/ghostty/config

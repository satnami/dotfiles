#!/bin/sh

# Make iTerm2 load its preferences from this directory. Idempotent; setup.sh runs it.
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/dotfiles/iTerm"

# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

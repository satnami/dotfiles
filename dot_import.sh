#!/usr/bin/env bash

NOW=$(date +"%Y_%m_%d_%H_%M_%S")

LOCATIONS="aliases bash_profile editorconfig exports functions gemrc gitconfig gitignore_global hushlogin psqlrc vimrc zshrc kerlrc history_preexec.sh p9k.zsh p10k.zsh"

for location in $LOCATIONS; do
  [ -f ~/.$location ] && cp ~/.$location ~/.$location.$NOW.backup
  [ -f ~/dotfiles/.$location ] && cp ~/dotfiles/.$location ~/.$location
done

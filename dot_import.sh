#!/usr/bin/env bash

NOW=$(date +"%Y_%m_%d_%H_%M_%S")

LOCATIONS="aliases bash_profile editorconfig exports functions gemrc gitconfig gitignore_global hushlogin psqlrc vimrc zshrc kerlrc history_preexec.sh p9k.zsh p10k.zsh"

for location in $LOCATIONS; do
    cp ~/.$location ~/.$location.$NOW.backup
    cp ~/dotfiles/.$location ~/.$location
done

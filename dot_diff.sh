#!/usr/bin/env bash

LOCATIONS="aliases bash_profile editorconfig exports functions gemrc gitconfig gitignore_global hushlogin psqlrc vimrc zshrc kerlrc history_preexec.sh"

for location in $LOCATIONS; do
    diff --color ~/dotfiles/.$location ~/.$location --unified=0
done

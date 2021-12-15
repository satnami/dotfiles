#!/usr/bin/env bash

LOCATIONS="aliases bash_profile editorconfig exports functions gemrc gitconfig gitignore_global hushlogin psqlrc vimrc kerlrc zshrc"

for location in $LOCATIONS; do
	cp ~/.$location .$location
done
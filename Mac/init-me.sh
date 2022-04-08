#!/usr/bin/env bash

brew bundle dump --all -f

brew tap > brew_tap.list
brew list > brew.list
brew list --casks > brew_cask.list

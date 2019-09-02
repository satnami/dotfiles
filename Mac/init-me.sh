#!/usr/bin/env bash

brew bundle dump

brew tap > brew_tap.list
brew list > brew.list
brew cask list > brew_cask.list

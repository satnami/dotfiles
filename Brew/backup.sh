#!/usr/bin/env bash

# Dump installed Homebrew packages into Brew/Brewfile (works from any directory).
brew bundle dump -f --describe --no-vscode --file="$(cd "$(dirname "$0")" && pwd)/Brewfile"

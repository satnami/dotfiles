#!/usr/bin/env bash

echo "=== Formulae ==="
brew info --json=v2 --installed --formula | jq -r '.formulae[] | "\(.name): \(.desc)"'

echo
echo "=== Casks ==="
brew info --json=v2 --installed --cask | jq -r '.casks[] | "\(.token): \(.desc)"'

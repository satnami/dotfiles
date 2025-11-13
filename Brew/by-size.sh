#!/bin/bash

echo "=== Formulae ==="
brew list --formula | while read -r f; do
  path=$(brew --cellar "$f")
  size=$(du -sh "$path" 2>/dev/null | cut -f1)
  printf "%-30s %10s\n" "$f" "$size"
done | sort -hr -k2

echo
echo "=== Casks ==="
brew list --cask | while read -r c; do
  path=$(brew --prefix)/Caskroom/"$c"
  size=$(du -sh "$path" 2>/dev/null | cut -f1)
  printf "%-30s %10s\n" "$c" "$size"
done | sort -hr -k2

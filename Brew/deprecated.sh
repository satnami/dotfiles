#!/bin/bash

echo "=== Formulae ==="
brew list --formula | while read -r formula; do
  info=$(brew info "$formula")
  if echo "$info" | grep -q "Deprecated"; then
    echo "Deprecated: $formula"
  elif echo "$info" | grep -q "Disabled"; then
    echo "Disabled: $formula"
  fi
done

echo
echo "=== Casks ==="
brew list --formula | while read -r formula; do
  if ! brew info "$formula" >/dev/null 2>&1; then
    echo "Not found in any tap: $formula"
  fi
done

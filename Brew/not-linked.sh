#!/usr/bin/env bash

set -euo pipefail

apps_dir="/Applications"
installed_file="$(mktemp)"
tokens_file="$(mktemp)"
trap 'rm -f "$installed_file" "$tokens_file"' EXIT

normalize_token() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g; s/-+/-/g'
}

# Apps already installed through Homebrew casks.
brew list --cask | while read -r cask; do
  brew info --cask "$cask" --json=v2 2>/dev/null \
    | jq -r '.casks[0].artifacts[]? | .app[]? // empty' \
    | sed 's/\.app$//'
done | sort -u > "$installed_file"

# Map every known cask app name to its token by scanning the local cask repo.
# This is much faster than calling `brew info` for every cask, and it preserves
# exact tokens such as `shutter-encoder`.
cask_repo="$(brew --repo homebrew/cask 2>/dev/null || true)"
if [ -n "$cask_repo" ] && [ -d "$cask_repo/Casks" ]; then
  find "$cask_repo/Casks" -name '*.rb' -print0 | \
    while IFS= read -r -d '' cask_file; do
      token="$(basename "$cask_file" .rb)"
      grep -E '^[[:space:]]*app "' "$cask_file" 2>/dev/null | \
        sed -nE 's/^[[:space:]]*app "(.+)\.app".*$/\1/p' | \
        while IFS= read -r app_name; do
          printf '%s\t%s\n' "$app_name" "$token"
        done
    done | sort -u > "$tokens_file"
else
  : > "$tokens_file"
fi

find "$apps_dir" -maxdepth 1 -name "*.app" -exec basename {} .app \; | sort | \
while read -r app; do
  if grep -Fxq "$app" "$installed_file"; then
    continue
  fi

  token="$(awk -F'\t' -v app="$app" '$1 == app { print $2; exit }' "$tokens_file")"
  if [ -z "$token" ]; then
    token="$(normalize_token "$app")"
  fi

  echo "$app"
  echo "  brew install --cask --force $token"
  echo
 done

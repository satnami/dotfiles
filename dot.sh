#!/usr/bin/env bash

# Unified dotfile management: init, import, backup, and diff
# Usage: dot.sh <init|import|backup|diff>

DOTFILES_DIR="$HOME/dotfiles"

# Files that live at ~/.<name> (names without the leading dot)
LOCATIONS="aliases bash_profile editorconfig exports functions gemrc gitconfig gitignore_global hushlogin psqlrc vimrc zshrc kerlrc history_preexec.sh"

# Files that live elsewhere: "<path in repo>|<path in home>". Empty for now;
# terminal configs are pointed at the repo by iTerm/setup.sh and ghostty/setup.sh.
EXTRAS=()

# Print every "<repo file>|<home file>" pair, one per line
pairs() {
  local location extra
  for location in $LOCATIONS; do
    printf '%s|%s\n' "$DOTFILES_DIR/.$location" "$HOME/.$location"
  done
  for extra in "${EXTRAS[@]}"; do
    printf '%s|%s\n' "$DOTFILES_DIR/${extra%%|*}" "${extra#*|}"
  done
}

# init: create files missing from ~, never touch existing ones (used by setup.sh).
# DRY_RUN=1 only reports what would be created.
dot_init() {
  pairs | while IFS='|' read -r src dst; do
    [ -f "$src" ] || continue
    [ -e "$dst" ] && continue
    if [ -n "${DRY_RUN:-}" ]; then
      echo "would create  $dst"
      continue
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "created  $dst"
  done
  echo "Init done (existing files untouched)"
}

# import: repo -> ~ for every file that differs, with a timestamped backup of each file replaced
dot_import() {
  local now
  now=$(date +"%Y_%m_%d_%H_%M_%S")
  pairs | while IFS='|' read -r src dst; do
    [ -f "$src" ] || continue
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      continue
    fi
    if [ -f "$dst" ]; then
      cp "$dst" "$dst.$now.backup"
      echo "updated  $dst  (backup: $dst.$now.backup)"
    else
      mkdir -p "$(dirname "$dst")"
      echo "created  $dst"
    fi
    cp "$src" "$dst"
  done
  echo "Import done"
}

# backup: ~ -> repo for every file that differs
dot_backup() {
  pairs | while IFS='|' read -r src dst; do
    [ -f "$dst" ] || continue
    if [ -f "$src" ] && cmp -s "$src" "$dst"; then
      continue
    fi
    cp "$dst" "$src" && echo "backed up  $dst -> $src"
  done
  echo "Backup done"
}

dot_diff() {
  pairs | while IFS='|' read -r src dst; do
    if [ -f "$src" ] && [ -f "$dst" ]; then
      diff --color "$src" "$dst" --unified=0
    fi
  done
}

case "${1:-}" in
  init)    dot_init ;;
  import)  dot_import ;;
  backup)  dot_backup ;;
  diff)    dot_diff ;;
  *)
    echo "Usage: dot.sh <init|import|backup|diff>"
    echo ""
    echo "  init    - Create files missing from ~, leave existing ones alone (setup.sh uses this)"
    echo "  import  - Copy repo dotfiles over ~/ where they differ (creates timestamped backups)"
    echo "  backup  - Copy ~/ dotfiles into the repo where they differ"
    echo "  diff    - Show differences between repo and ~/"
    exit 1
    ;;
esac

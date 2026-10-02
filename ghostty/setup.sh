#!/bin/sh

# Make Ghostty read its config from this directory, the way iTerm/setup.sh
# points iTerm2 at the repo: the live config becomes a symlink to ./config.
# Idempotent; setup.sh runs it. A live file that differs from the repo copy is
# kept as a timestamped .backup next to the link.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$REPO_DIR/config"
DST="$HOME/Library/Application Support/com.mitchellh.ghostty/config"

if [ -L "$DST" ] && [ "$(readlink "$DST")" = "$SRC" ]; then
  echo "ok     $DST -> $SRC"
  exit 0
fi

if [ -L "$DST" ]; then
  rm "$DST"                                   # link to somewhere else
elif [ -f "$DST" ]; then
  if cmp -s "$SRC" "$DST"; then
    rm "$DST"                                 # same content, nothing to keep
  else
    BACKUP="$DST.$(date +%Y%m%d_%H%M%S).backup"
    mv "$DST" "$BACKUP"
    echo "kept   $BACKUP (differed from repo)"
  fi
fi

mkdir -p "$(dirname "$DST")"
ln -s "$SRC" "$DST"
echo "linked $DST -> $SRC"

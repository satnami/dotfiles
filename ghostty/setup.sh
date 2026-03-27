#!/usr/bin/env bash

GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$GHOSTTY_DIR"
[ -f "$GHOSTTY_DIR/config" ] && cp "$GHOSTTY_DIR/config" "$GHOSTTY_DIR/config.$(date +%Y%m%d_%H%M%S).backup"
cp config "$GHOSTTY_DIR/config"

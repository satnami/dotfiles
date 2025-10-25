#!/bin/bash
# Usage: rename_ext.sh oldext newext

for f in *.$1; do
  mv "$f" "${f%.$1}.$2"
done

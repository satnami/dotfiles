#!/bin/bash

for ext in "$@"; do
  echo "$ext: $(ls *.$ext 2>/dev/null | wc -l)"
done

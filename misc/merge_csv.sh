#!/usr/bin/env bash
# Usage: merge_csv.sh output.csv file1.csv file2.csv ...

head -1 "$2" > "$1"
for f in "$@"; do
  if [ "$f" != "$1" ]; then
    tail -n +2 "$f" >> "$1"
  fi
done

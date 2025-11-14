#!/usr/bin/env bash
# Usage: ./append_every_nth.sh 3 " 🚀" input.txt output.txt

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 3 ' 🚀' input.txt output.txt"
  exit 1
fi

INTERVAL=$1
TEXT=$2
INPUT=$3
OUTPUT=$4

awk -v n="$INTERVAL" -v t="$TEXT" 'NR % n == 0 {$0 = $0 t} 1' "$INPUT" > "$OUTPUT"

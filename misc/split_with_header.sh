#!/bin/bash
# Usage: ./split_with_header.sh input.csv 1000 8 csv
#        $1 = input file
#        $2 = lines per chunk (excluding header)
#        $3 = number of header lines
#        $4 = suffix (e.g., csv, txt)

INPUT=$1
LINES=$2
HEADER_LINES=$3
SUFFIX=$4

if [[ -z "$INPUT" || -z "$LINES" || -z "$HEADER_LINES" || -z "$SUFFIX" ]]; then
  echo "Usage: $0 <inputfile> <lines_per_chunk> <header_lines> <suffix>"
  exit 1
fi

# Extract base name without extension
BASENAME=$(basename "$INPUT")
NAME="${BASENAME%.*}"

# Extract header
HEADER=$(head -n "$HEADER_LINES" "$INPUT")

# Split file (skipping header)
tail -n +"$((HEADER_LINES+1))" "$INPUT" | split -l "$LINES" - chunk_

# Add header back and rename
i=1
for f in chunk_*; do
  OUT="${NAME}_part_${i}.${SUFFIX}"
  { echo "$HEADER"; cat "$f"; } > "$OUT"
  rm "$f"
  echo "Created $OUT"
  i=$((i+1))
done

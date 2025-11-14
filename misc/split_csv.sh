#!/usr/bin/env bash
# Usage: ./split_csv.sh input.csv 100

FILE=$1
LINES_PER_FILE=$2
HEADER=$(head -n 1 "$FILE")

# Remove header and split into chunks of $LINES_PER_FILE lines
tail -n +2 "$FILE" | split -l $LINES_PER_FILE - chunk_

# Add the header back to each chunk
for f in chunk_*; do
  (echo "$HEADER"; cat "$f") > "${f}.csv"
  rm "$f"
done

echo "Split complete. Created $(ls chunk_*.csv | wc -l) files."

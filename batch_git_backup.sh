#!/bin/bash

DRY_RUN=false   # ustaw true jeśli chcesz test

BACKUP="/c/Users/admin_test/Desktop/hook/3dstudiopoland-bot/1BULK_Backup"
BATCH=100
SLEEP=120

COUNTER_FILE=".commit_counter"

mkdir -p "$BACKUP"

if [ ! -f "$COUNTER_FILE" ]; then
  echo 1 > "$COUNTER_FILE"
fi

while true; do

  git ls-files --others --exclude-standard > all_files.txt
  TOTAL=$(wc -l < all_files.txt)

  if [ "$TOTAL" -lt "$BATCH" ]; then
    echo "Only $TOTAL files left. Less than $BATCH. Stopping loop."
    rm all_files.txt
    exit 0
  fi

  head -n $BATCH all_files.txt > batch.txt

  COMMIT_NO=$(cat "$COUNTER_FILE")

  echo "Processing batch commit $COMMIT_NO"

  if [ "$DRY_RUN" = true ]; then
    cat batch.txt
    echo "DRY RUN"
    sleep $SLEEP
    continue
  fi

  BDIR="$BACKUP/batch_$COMMIT_NO"
  mkdir -p "$BDIR"

  while read file; do
    mkdir -p "$BDIR/$(dirname "$file")"
    cp "$file" "$BDIR/$file"
  done < batch.txt

  git add -f --pathspec-from-file=batch.txt
  git commit -m "Auto batch $COMMIT_NO"
  git push || exit 1

  echo $((COMMIT_NO+1)) > "$COUNTER_FILE"

  echo "Sleeping $SLEEP seconds..."
  sleep $SLEEP

done

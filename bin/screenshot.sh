#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

SAVE_FILE=false
FILENAME=""

while getopts "s" opt; do
  case $opt in
    s) SAVE_FILE=true ;;
    *) echo "Usage: $0 [-s [filename]]"; exit 1 ;;
  esac
done

shift $((OPTIND - 1))
FILENAME=$1

TMP_FILE=$(mktemp)

grim -g "$(slurp)" - > "$TMP_FILE"

wl-copy < "$TMP_FILE"

# If -s was passed, move/copy the file to the save location
if [ "$SAVE_FILE" = true ]; then
  if [ -z "$FILENAME" ]; then
    FILENAME="$(date +%Y-%m-%d_%H-%M-%S).png"
  fi
  
  if [[ ! "$FILENAME" == *.png ]]; then
    FILENAME="${FILENAME}.png"
  fi
  
  mv "$TMP_FILE" "$SAVE_DIR/$FILENAME"
  echo "Saved to $SAVE_DIR/$FILENAME"
else
  # Clean up if not saving
  rm "$TMP_FILE"
fi
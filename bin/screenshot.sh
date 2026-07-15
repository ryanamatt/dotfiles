#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

SAVE_FILE=false
FILENAME=""

function usage() {
  echo "Usage: $0 [-s [filename]] [-h|--help]"
  echo "  -s [filename]  Save the screenshot to $SAVE_DIR"
  echo "  -h, --help     Show this help message"
  exit 0
}

while getopts "sh" opt; do
  case $opt in
    s) SAVE_FILE=true ;;
    h) usage ;;
    *) usage ;;
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
  notify-send "Screenshot Saved" "File saved to $SAVE_DIR/$FILENAME"
else
  # Clean up if not saving
  rm "$TMP_FILE"
  notify-send "Screenshot" "Screenshot copied to clipboard."
fi
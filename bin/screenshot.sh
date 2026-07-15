#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

SAVE_FILE=false
FULL_MONITOR=false
FILENAME=""

function usage() {
  echo "Usage: $0 [-s [filename]] [-h|--help]"
  echo "  -s [filename]  Save the screenshot to $SAVE_DIR"
  echo "  -w             Takes a Screenshot of Entire Current Montior"
  echo "  -h, --help     Show this help message"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -s)
      SAVE_FILE=true
      # Check if the next argument is a filename (doesn't start with -)
      if [[ -n "$2" && "$2" != -* ]]; then
        FILENAME="$2"
        shift
      fi
      ;;
    -w) FULL_MONITOR=true ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
  shift
done

TMP_FILE=$(mktemp)

if [ "$FULL_MONITOR" = true ]; then
  GEOMETRY=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x),\(.y) \(.width)x\(.height)"')
  grim -g "$GEOMETRY" - > "$TMP_FILE"
else
  grim -g "$(slurp)" - > "$TMP_FILE"
fi

wl-copy < "$TMP_FILE"

# If -s was passed, move/copy the file to the save location
if [ "$SAVE_FILE" = true ]; then
  [ -z "$FILENAME" ] && FILENAME="$(date +%Y-%m-%d_%H-%M-%S).png"
  [[ ! "$FILENAME" == *.png ]] && FILENAME="${FILENAME}.png"
  
  mv "$TMP_FILE" "$SAVE_DIR/$FILENAME"
  echo "Saved to $SAVE_DIR/$FILENAME"
  notify-send "Screenshot Saved" "File saved to $SAVE_DIR/$FILENAME"
else
  # Clean up if not saving
  rm "$TMP_FILE"
  notify-send "Screenshot" "Screenshot copied to clipboard."
fi
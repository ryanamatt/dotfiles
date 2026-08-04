#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/dotfiles/wallpapers"
STATE_FILE="$WALLPAPER_DIR/.wallpaper_state.json"
input="$1"

mkdir -p "$WALLPAPER_DIR"

# Ensure the JSON state file exists and is valid
if [ ! -f "$STATE_FILE" ]; then
    echo '{}' > "$STATE_FILE"
fi

if [ -z "$input" ]; then
    echo "Error: Please provide a theme or a wallpaper image/gif/vid."
    exit 1
fi

theme=""
wallpaper=""

if [ -d "$WALLPAPER_DIR/$input" ]; then
    theme="$input"
    saved=$(jq -r --arg theme "$theme" '.[$theme] // empty' "$STATE_FILE")

    if [ -n "$saved" ] && [ -f "$saved" ]; then
        # Reuse the last-used wallpaper for this theme
        wallpaper="$saved"
    else
        # No saved entry (or file went missing) - fall back to first file in the dir
        wallpaper=$(find "$WALLPAPER_DIR/$input" -maxdepth 1 -type f | sort | head -n 1)
    fi
elif [ -f "$input" ]; then
    wallpaper=$(realpath "$input")
    # Infer the theme from the wallpaper's parent directory
    theme=$(basename "$(dirname "$wallpaper")")
fi

if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
    awww img --transition-type center --transition-step 90 --transition-fps 60 --transition-duration 2 "$wallpaper"

    if [ -n "$theme" ]; then
        tmp=$(mktemp)
        jq --arg theme "$theme" --arg wp "$wallpaper" '.[$theme] = $wp' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi

    echo "Wallpaper set to: $(basename "$wallpaper") (theme: ${theme:-none})"
else
    echo "Error: Wallpaper or theme not found."
    exit 1
fi

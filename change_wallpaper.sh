#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/dotfiles/wallpapers/"
STATE_FILE="$WALLPAPER_DIR/.current_wallpaper"
input="$1"

mkdir -p "$(dirname "$STATE_FILE")"

if [ -d "$WALLPAPER_DIR/$input" ]; then
    wallpaper=$(find "$WALLPAPER_DIR/$input" -maxdepth 1 -type f | head -n 1)
else
    wallpaper="$input"
fi

if [ -f "$wallpaper" ]; then
    awww img --transition-type center --transition-step 90 --transition-fps 60 --transition-duration 2 "$wallpaper"
    echo "$(basename "$wallpaper")" > "$STATE_FILE"
    echo "Wallpaper set to: $(basename "$wallpaper")"
else
    echo "Error: Wallpaper or theme not found."
    exit 1
fi
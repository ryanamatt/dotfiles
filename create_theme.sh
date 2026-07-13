#!/bin/bash

# Check if a theme name was provided
if [ -z "$1" ]; then
    echo "Usage: ./create_theme.sh <theme_name>"
    exit 1
fi

THEME=$1
BASE_DIR="themes/$THEME"

echo "Creating structure for theme: $THEME..."

# Create directories
mkdir -p "$BASE_DIR/fastfetch"
mkdir -p "$BASE_DIR/fish"
mkdir -p "$BASE_DIR/hypr/modules"
mkdir -p "$BASE_DIR/kitty"
mkdir -p "$BASE_DIR/rofi/app-launcher/colors"
mkdir -p "$BASE_DIR/swaync/colors"
mkdir -p "$BASE_DIR/waybar/colors"
mkdir -p "$BASE_DIR/theme-switcher/colors"

# Create files
touch "$BASE_DIR/fastfetch/config.jsonc"
touch "$BASE_DIR/fish/fish_variables"
touch "$BASE_DIR/hypr/hyprlock.conf"
touch "$BASE_DIR/hypr/modules/colors.lua"
touch "$BASE_DIR/kitty/theme_colors.conf"
touch "$BASE_DIR/rofi/app-launcher/colors/theme_colors.rasi"
touch "$BASE_DIR/starship.toml"
touch "$BASE_DIR/swaync/colors/theme_colors.css"
touch "$BASE_DIR/waybar/colors/theme_colors.css"

echo "Done! Structure created in $BASE_DIR/"
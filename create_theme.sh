#!/bin/bash
set -euo pipefail

# Check if a theme name was provided
if [ -z "${1:-}" ]; then
    echo "Usage: ./create_theme.sh <ThemeName>"
    echo "  looks for theme-references/<themename-lowercase>.yaml"
    exit 1
fi

THEME=$1
SLUG=$(echo "$THEME" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
YAML="theme-references/${SLUG}.yaml"
BASE_DIR="themes/$THEME"
CONF_DIR="${BASE_DIR}/.config"

if [ ! -f "$YAML" ]; then
    echo "error: $YAML not found."
    echo "Write out the palette there first (see theme-references/arcane.yaml for the schema), then rerun."
    exit 1
fi

echo "Creating structure for theme: $THEME..."

# Create directories (generate_theme.py also does this, but keep it here
# so the skeleton exists even if colors aren't filled in / generator fails)
mkdir -p "$CONF_DIR/fastfetch"
mkdir -p "$CONF_DIR/fish"
mkdir -p "$CONF_DIR/hypr/modules"
mkdir -p "$CONF_DIR/kitty"
mkdir -p "$CONF_DIR/swaync/colors"
mkdir -p "$BASE_DIR/quickshell"

echo "Rendering colors from $YAML..."
./generate_theme.py "$YAML" --out "$BASE_DIR"

echo "Done! Structure + colors created in $BASE_DIR/"
echo "Manual step: drop your ascii art at ${CONF_DIR}/fastfetch/<name>.txt"
echo "cp an existing fastfetch config and drop in in your theme replacing"
echo "the ascii art one liner with your own."

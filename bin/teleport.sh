#!/bin/bash

# teleport.sh - A directory bookmarking utility.
# 
# Usage: 
#   teleport add <tag>    - Bookmark current directory
#   teleport <tag>        - Jump to a bookmarked directory
#   teleport list         - Show all tags
#   teleport remove <tag> - Delete a specific tag
#   teleport clear        - Remove all tags

# Define Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Storage file
TP_FILE="$HOME/.config/.teleport_bookmarks"

# Ensure storage file exists
touch "$TP_FILE"

case "$1" in
    "add")
        if [ -z "$2" ]; then
            echo -e "${RED}Error:${NC} Please provide a tag name. Usage: teleport add [tag]"
        else
            # Remove tag if it already exists to prevent duplicates
            sed -i "/^$2 /d" "$TP_FILE"
            echo "$2 $(pwd)" >> "$TP_FILE"
            echo -e "${GREEN}Tagged:${NC} $2 -> $(pwd)"
        fi
        ;;

    "list")
        echo -e "${BLUE}Teleport Bookmarks:${NC}"
        if [ ! -s "$TP_FILE" ]; then
            echo "No tags saved yet."
        else
            column -t -s ' ' "$TP_FILE"
        fi
        ;;

    "remove")
        if [ -z "$2" ]; then
            echo -e "${RED}Error:${NC} Specify a tag to remove."
        else
            sed -i "/^$2 /d" "$TP_FILE"
            echo -e "${GREEN}Removed tag:${NC} $2"
        fi
        ;;

    "clear")
        > "$TP_FILE"
        echo -e "${RED}All bookmarks cleared.${NC}"
        ;;

    "")
        echo -e "${BLUE}Usage:${NC} teleport [tag | add <tag> | list | remove <tag> | clear]"
        ;;

    *)
        # Default behavior: Attempt to teleport to the tag
        TARGET=$(grep "^$1 " "$TP_FILE" | cut -d' ' -f2-)
        if [ -d "$TARGET" ]; then
            echo -e "${GREEN}Teleporting to:${NC} $TARGET"
            cd "$TARGET" || return
        else
            echo -e "${RED}Error:${NC} Tag '$1' not found or directory no longer exists."
            return 1
        fi
        ;;
esac
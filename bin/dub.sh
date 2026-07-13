#!/bin/bash

# dub.sh - A utility to nickname complex commands.
# 
# Usage: 
#   dub add <name> <cmd> - Give a command a nickname
#   dub <name>           - Execute a dubbed command
#   dub list             - Show all nicknames
#   dub remove <name>    - Delete a specific nickname
#   dub clear            - Remove all nicknames

# Define Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Storage file
DUB_FILE="$HOME/.config/.dub_aliases"

# Ensure storage file exists
touch "$DUB_FILE"

case "$1" in
    "add")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Error:${NC} Usage: dub add [name] [command]"
        else
            # Remove name if it already exists to prevent duplicates
            sed -i "/^$2 /d" "$DUB_FILE"
            # Capture everything after the nickname as the command
            shift
            NAME=$1
            shift
            COMMAND=$@
            echo "$NAME $COMMAND" >> "$DUB_FILE"
            echo -e "${GREEN}Dubbed:${NC} $NAME -> $COMMAND"
        fi
        ;;

    "list")
        echo -e "${CYAN}Dubbed Commands:${NC}"
        if [ ! -s "$DUB_FILE" ]; then
            echo "No nicknames saved yet."
        else
            echo -e "Name   Command"
            column -t -s ' ' "$DUB_FILE"
        fi
        ;;

    "remove")
        if [ -z "$2" ]; then
            echo -e "${RED}Error:${NC} Specify a nickname to remove."
        else
            sed -i "/^$2 /d" "$DUB_FILE"
            echo -e "${GREEN}Removed nickname:${NC} $2"
        fi
        ;;

    "clear")
        > "$DUB_FILE"
        echo -e "${RED}All nicknames cleared.${NC}"
        ;;

    "")
        echo -e "${CYAN}Usage:${NC} dub [name | add <name> <cmd> | list | remove <name> | clear]"
        ;;

    *)
        # Default behavior: Attempt to run the dubbed command
        # Matches the nickname at the start of the line and extracts the rest
        CMD_TO_RUN=$(grep "^$1 " "$DUB_FILE" | cut -d' ' -f2-)
        if [ -n "$CMD_TO_RUN" ]; then
            echo -e "${GREEN}Running:${NC} $CMD_TO_RUN"
            eval "$CMD_TO_RUN"
        else
            echo -e "${RED}Error:${NC} Nickname '$1' not found."
            return 1
        fi
        ;;
esac

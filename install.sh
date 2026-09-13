#!/usr/bin/env bash
# install.sh -- Shell dotfiles installer/uninstaller

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALL=false

# Check for uninstall flag
if [[ "$1" == "-u" || "$1" == "--uninstall" ]]; then
    UNINSTALL=true
fi

# Symlink/Remove logic
link() {
    local src="$DOTFILES/$1"
    local dst="$HOME/$2" 

    if [ "$UNINSTALL" = true ]; then
        if [ -L "$dst" ]; then
            rm "$dst"
            echo "  removed symlink $dst"
            # Restore .bak if it exists
            if [ -f "$dst.bak" ]; then
                mv "$dst.bak" "$dst"
                echo "  restored backup $dst.bak → $dst"
            fi
        fi
    else
        mkdir -p "$(dirname "$dst")"
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            echo "  backing up $dst → $dst.bak"
            mv "$dst" "$dst.bak"
        fi
        ln -sf "$src" "$dst"
        echo "  linked $1 → $2"
    fi
}

if [ "$UNINSTALL" = true ]; then
    echo "Uninstalling Arcane Shell dotfiles..."
else
    echo "Installing Arcane Shell dotfiles..."
fi

# Helper wrapper (kept around for one-off files outside .config)
link_config() {
    link "$1" "$1"
}

# Files under .config/ to skip (glob patterns, matched against path relative to .config/)
EXCLUDE_PATTERNS=(
    "swaync/README.md"
)

is_excluded() {
    local rel="$1"
    local pattern
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        # shellcheck disable=SC2053
        if [[ "$rel" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Link every file under .config/ to the matching path under ~/.config/
if [ -d "$DOTFILES/.config" ]; then
    while IFS= read -r -d '' file; do
        rel="${file#"$DOTFILES/.config/"}"
        if is_excluded "$rel"; then
            echo "  skipping .config/$rel (excluded)"
            continue
        fi
        link ".config/$rel" ".config/$rel"
    done < <(find "$DOTFILES/.config" -type f -print0)
fi

# Install custom scripts from the bin directory
if [ -d "$DOTFILES/bin" ]; then
    echo "Installing custom scripts..."
    for file in "$DOTFILES/bin"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            
            # Strip .sh, .py, or .awk extensions for cleaner command names
            case "$filename" in
                *.sh)  cmd_name="${filename%.sh}" ;;
                *.py)  cmd_name="${filename%.py}" ;;
                *.awk) cmd_name="${filename%.awk}" ;;
                *)     cmd_name="$filename" ;;
            esac
            
            link "bin/$filename" ".local/bin/$cmd_name"
        fi
    done
fi

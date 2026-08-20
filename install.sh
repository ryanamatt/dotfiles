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

# Helper wrapper
link_config() {
    link "$1" "$1"
}

link_config ".config/fish/config.fish"
link_config ".config/fish/conf.d/fish-color.fish"

link_config ".config/kitty/kitty.conf"

link_config ".config/starship.toml"

link_config ".config/fastfetch/config.jsonc"
link_config ".config/fastfetch/art.txt"

link_config ".config/swaync/config.json"
link_config ".config/swaync/style.css"

link_config ".config/hypr/hyprland.lua"
link_config ".config/hypr/modules/autostart.lua"
link_config ".config/hypr/modules/binds.lua"
link_config ".config/hypr/modules/decorations.lua"
link_config ".config/hypr/modules/env.lua"
link_config ".config/hypr/modules/input.lua"
link_config ".config/hypr/modules/layout.lua"
link_config ".config/hypr/modules/misc.lua"
link_config ".config/hypr/modules/monitors.lua"
link_config ".config/hypr/modules/window_rules.lua"

link_config ".config/hypr/hypridle.conf"

link_config ".config/Orpheus/orpheus.config"

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

if [[ ! uninstall ]]; then
    echo "Setting Theme to Arcane"
    ./switcher.sh Arcane
fi
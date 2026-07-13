#!/usr/bin/env bash
#
# theme-switcher.sh — swap color/theme files in ~/.config and ~/dotfiles/quickshell
#
# Layout expected:
#   ~/dotfiles/themes/<ThemeName>/.config/kitty/theme_colors.conf
#   ~/dotfiles/themes/<ThemeName>/.config/hypr/...      (mirrors ~/.config structure)
#   ~/dotfiles/themes/<ThemeName>/quickshell/colors.json
#
#   ~/.config/kitty/theme_colors.conf     (live config — install.sh symlinks
#   ~/.config/hypr/...                     most files here individually from
#                                           dotfiles/.config; this script only
#                                           overwrites paths that exist under
#                                           themes/<ThemeName>/.config)
#   ~/dotfiles/quickshell/colors.json      (live quickshell colors)
#
# For every file found under themes/<ThemeName>/.config/, a symlink is
# created at the matching path under ~/.config/ pointing back into the
# theme dir. For every file found under themes/<ThemeName>/quickshell/, a
# symlink is created at the matching path under ~/dotfiles/quickshell/
# instead. Nothing else in either destination is touched. If a real
# (non-symlink) file already sits at a destination, it's backed up once
# as `<file>.bak`.
#
# Usage:
#   theme-switcher.sh <ThemeName>   Switch to ThemeName
#   theme-switcher.sh -l|--list     List available themes
#   theme-switcher.sh -c|--current  Show currently active theme
#   theme-switcher.sh -n|--dry-run <ThemeName>  Preview without changing anything

set -euo pipefail

DOTFILES="$HOME/dotfiles"
THEMES_DIR="$DOTFILES/themes"
CONFIG_DIR="$HOME/.config"
STATE_FILE="$THEMES_DIR/.current_theme"
QUICKSHELL_DIR="$DOTFILES/quickshell"

# ----- colors for output -----
c_green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
c_yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
c_red() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; }
c_blue() { printf '\033[1;34m%s\033[0m\n' "$*"; }

usage() {
    sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

list_themes() {
    if [[ ! -d "$THEMES_DIR" ]]; then
        c_red "No themes directory found at $THEMES_DIR"
        exit 1
    fi
    local current
    current=$(cat "$STATE_FILE" 2>/dev/null || echo "")
    find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort |
        while read -r t; do
            if [[ "$t" == "$current" ]]; then
                c_green "* $t (active)"
            else
                echo "  $t"
            fi
        done
}

current_theme() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        c_yellow "No theme recorded yet."
    fi
}

# Reload the apps that need a nudge to pick up new colors.
# Edit/extend this list for your setup.
reload_apps() {
    c_blue "Reloading apps..."

    if command -v hyprctl >/dev/null 2>&1 && pgrep -x Hyprland >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 && echo "  hyprland reloaded"
    fi

    if pgrep -x kitty >/dev/null 2>&1; then
        pkill -SIGUSR1 kitty 2>/dev/null && echo "  kitty reloaded"
    fi

    # if pgrep -x waybar >/dev/null 2>&1; then
    #     pkill -SIGUSR2 waybar 2>/dev/null && echo "  waybar reloaded"
    # fi

    if pgrep -x swaync >/dev/null 2>&1; then
        pkill -SIGUSR2 swaync 2>/dev/null && echo "  swaync reloaded"
    fi
}

apply_razer_colors() {
    local theme_path="$1"
    local json_file="$theme_path"/quickshell/colors.json

    if [[ ! -f "$json_file" ]]; then
        c_yellow "No Razer color file found at $json_file"
        return
    fi

    local color
    color=$(jq -r '.accent' "$json_file" | sed 's/#//')

    c_blue "Apply Razer lighting: #$color"

    if command -v razer-cli >/dev/null 2>&1; then
        razer-cli -c "$color"
    else
        c_red "razer-cli not found. Please install it to sync lightning."
    fi
}

# Symlink every file under $src_root into $dest_root, preserving the
# relative path. Backs up a real (non-symlink) file at the destination
# once, as `<file>.bak`. Sets $LINK_COUNT to the number of files linked
# (0 if src_root doesn't exist). In dry-run mode, nothing is touched,
# only printed, and $LINK_COUNT stays 0.
LINK_COUNT=0
link_tree() {
    local src_root="$1"
    local dest_root="$2"
    local dry_run="$3"
    LINK_COUNT=0

    [[ -d "$src_root" ]] || return 0

    while IFS= read -r -d '' src; do
        local rel="${src#"$src_root"/}"
        local dest="$dest_root/$rel"
        local dest_dir
        dest_dir="$(dirname "$dest")"

        if [[ "$dry_run" == true ]]; then
            echo "  $rel  ->  $dest"
            continue
        fi

        mkdir -p "$dest_dir"

        # If a real file (not a symlink) is sitting there, back it up once.
        if [[ -e "$dest" && ! -L "$dest" ]]; then
            mv "$dest" "$dest.bak"
            c_yellow "  backed up existing $dest -> $dest.bak"
        fi

        ln -sfn "$src" "$dest"
        echo "  linked $rel -> $dest"
        LINK_COUNT=$((LINK_COUNT + 1))
    done < <(find "$src_root" -type f -print0)
}

switch_theme() {
    local theme="$1"
    local dry_run="${2:-false}"
    local theme_path="$THEMES_DIR/$theme"

    if [[ ! -d "$theme_path" ]]; then
        c_red "Theme '$theme' not found in $THEMES_DIR"
        echo "Available themes:"
        list_themes
        exit 1
    fi

    c_blue "Switching to theme: $theme"
    [[ "$dry_run" == true ]] && c_yellow "(dry run — no changes will be made)"

    ~/dotfiles/change_wallpaper.sh "$theme"

    link_tree "$theme_path/.config" "$CONFIG_DIR" "$dry_run"
    local config_count=$LINK_COUNT
    link_tree "$theme_path/quickshell" "$QUICKSHELL_DIR" "$dry_run"
    local quickshell_count=$LINK_COUNT

    if [[ "$dry_run" == true ]]; then
        return 0
    fi

    local count=$((config_count + quickshell_count))

    if [[ $count -eq 0 ]]; then
        c_yellow "No files found under $theme_path/.config or $theme_path/quickshell — nothing linked."
        exit 1
    fi

    echo "$theme" > "$STATE_FILE"

    apply_razer_colors "$theme_path"

    c_green "Theme '$theme' applied ($count file(s) linked)."

    reload_apps
}

# --- arg parsing ---
case "${1:-}" in
    -l|--list)
        list_themes
        ;;
    -c|--current)
        current_theme
        ;;
    -n|--dry-run)
        [[ -n "${2:-}" ]] || usage
        switch_theme "$2" true
        ;;
    -h|--help|"")
        usage
        ;;
    *)
        switch_theme "$1" false
        ;;
esac
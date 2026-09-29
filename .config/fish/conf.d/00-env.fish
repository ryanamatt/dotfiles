# Environment variables and PATH
# Runs for every fish process, so scripts and non-interactive shells get these too.

# --- Editors ---
set -gx EDITOR orp
set -gx VISUAL code

# --- XDG base directories ---
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache

# --- PATH ---
fish_add_path -g $HOME/.local/bin
fish_add_path -g $HOME/go/bin

# --- Teleport ---
# Bookmark file used by the `teleport` function and its completions.
# Format: one "<tag> <absolute path>" pair per line.
set -g TELEPORT_FILE $XDG_CONFIG_HOME/.teleport_bookmarks

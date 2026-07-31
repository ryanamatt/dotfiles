if status is-interactive

if command -q fastfetch
    fastfetch
    set -g fish_greeting ""
else
    set fish_greeting
end

# Editor
set -gx EDITOR code
set -gx VISUAL code

# XDG
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache

# Path
fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin

# --- Abbreviations ---

# System
abbr -a q 'exit'
abbr -a c 'clear'
abbr -a e '$EDITOR'
abbr -a se 'sudo $EDTIOR'

# Navigation
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'
abbr -a .... 'cd ../../..'

# yay / pacman
abbr -a y 'yay'
abbr -a yi 'yay -S'
abbr -a yr 'yay -Rns'
abbr -a yu 'yay -Syu'
abbr -a yq 'yay -Q'
abbr -a ys 'yay -Ss'

# Git
abbr -a g 'git'
abbr -a ga 'git add'
abbr -a gaa 'git add -A'
abbr -a gc 'git commit'
abbr -a gcm 'git commit -m'
abbr -a gp 'git push'
abbr -a gl 'git log --oneline --graph --decorate'
abbr -a gs 'git status'
abbr -a gd 'git diff'
abbr -a gco 'git checkout'
abbr -a gcb 'git checkout -b'

# Hyprland
abbr -a hypr-reload 'hyprctl reload'
abbr -a hypr-log 'journalctl --user -u hyprland -f'

# Swaync
abbr -a swaync-reload 'swaync-client --reload-config'

# gocryptfs
abbr -a vo "gocryptfs ~/.vault ~/vault"
abbr -a vc "fusermount3 -u ~/vault"

# Razer
abbr -a razer "polychromatic-controller & disown"

# Obsidian
abbr -a obsidian 'flatpak run md.obsidian.Obsidian & disown'
abbr -a obs-studio 'flatpak run com.obsproject.Studio & disown'

# Custom Bin Abbreviations
abbr -a tp "teleport"

# --- Functions ---

# mkcd - Make a directory and cd into it
function mkcd -d "Crate a directory and cd into it"
    mkdir -p $argv[1] && cd $argv[1]
end

# up N - go up N directories
function up -d "Go up N directories"
    set -l n (coalesce $argv[1] 1)
    set path ""
    for i in (seq $n)
        set path "../path"
    end
    cd $path
end

# extract - universal archive extractor
function extract -d "Extract any archive"
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'  ; tar xjf $argv[1]
            case '*.tar.gz'   ; tar xzf $argv[1]
            case '*.tar.xz'   ; tar xJf $argv[1]
            case '*.tar.zst'  ; tar --use-compress-program=unzstd -xf $argv[1]
            case '*.bz2'      ; bunzip2 $argv[1]
            case '*.gz'       ; gunzip $argv[1]
            case '*.tar'      ; tar xf $argv[1]
            case '*.tbz2'     ; tar xjf $argv[1]
            case '*.tgz'      ; tar xzf $argv[1]
            case '*.zip'      ; unzip $argv[1]
            case '*.7z'       ; 7z x $argv[1]
            case '*.zst'      ; unzstd $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted - unknown format"
        end
    else
        echo "'$argv[1]' is not a file"
    end
end

function auto_activate_venv --on-variable PWD
    if test -d venv
        # Check if we are already in the venv to avoid redundant sourcing
        if not string match -q "$PWD/venv*" "$VIRTUAL_ENV"
            source venv/bin/activate.fish
            echo -e "\e[32m(V) Activated Virtual Environment\e[0m"
        end
    else if test -n "$VIRTUAL_ENV"
        # Deactivate if we leave the directory containing the venv
        deactivate
        echo -e "\e[31m(V) Deactivated Virtual Environment\e[0m"
    end
end

function teleport
    set -l TP_FILE "$HOME/.config/.teleport_bookmarks"

    # Ensure storage file exists
    touch "$TP_FILE"

    switch "$argv[1]"
        case "add"
            if test -z "$argv[2]"
                echo -e "\033[0;31mError:\033[0m Please provide a tag name. Usage: teleport add [tag]"
            else
                # Remove tag if it already exists to prevent duplicates
                sed -i "/^$argv[2] /d" "$TP_FILE"
                echo "$argv[2] $PWD" >> "$TP_FILE"
                echo -e "\033[0;32mTagged:\033[0m $argv[2] -> $PWD"
            end

        case "list"
            echo -e "\033[0;34mTeleport Bookmarks:\033[0m"
            if test ! -s "$TP_FILE"
                echo "No tags saved yet."
            else
                column -t -s ' ' "$TP_FILE"
            end

        case "remove"
            if test -z "$argv[2]"
                echo -e "\033[0;31mError:\033[0m Specify a tag to remove."
            else
                sed -i "/^$argv[2] /d" "$TP_FILE"
                echo -e "\033[0;32mRemoved tag:\033[0m $argv[2]"
            end

        case "clear"
            true > "$TP_FILE"
            echo -e "\033[0;31mAll bookmarks cleared.\033[0m"

        case ""
            echo -e "\033[0;34mUsage:\033[0m teleport [tag | add <tag> | list | remove <tag> | clear]"

        case "*"
            # Default behavior: Attempt to teleport to the tag
            set -l TARGET (grep "^$argv[1] " "$TP_FILE" | cut -d' ' -f2-)
            if test -d "$TARGET"
                echo -e "\033[0;32mTeleporting to:\033[0m $TARGET"
                cd "$TARGET"
            else
                echo -e "\033[0;31mError:\033[0m Tag '$argv[1]' not found or directory no longer exists."
                return 1
            end
    end
end

function vscode_open_cwd

    # Get the ID of the currently active workspace in Hyprland
    set -l active_workspace (hyprctl activeworkspace -j | jq -r '.id' 2>/dev/null)

    # Fetch the title of a VS Code window on the specific workspace
    set -l vscode_title (hyprctl clients -j | jq -r --arg ws "$active_workspace" 'first(.[] | select((.class == "code" or .initialClass == "code" or .class == "code-url-handler") and (.workspace.id == ($ws | tonumber))) | .title)' 2>/dev/null)

    if test -n "$vscode_title"; and test "$vscode_title" != "null"
        set -l clean_path (string replace -r ' - Visual Studio Code$' '' $vscode_title)

        set -l expanded_path (string replace -r '^~' "$HOME" $clean_path)

        set -l target_dir
        if test -f "$expanded_path"
            set target_dir (dirname "$expanded_path")
        else if test -d "$expanded_path"
            set target_dir "$expanded_path"
        end

        if test -n "$target_dir"; and test -d "$target_dir"; and test "$target_dir" != "$PWD"
            cd "$target_dir"
        end
    end
end

end # end is-interactive

# Starship
starship init fish | source

vscode_open_cwd
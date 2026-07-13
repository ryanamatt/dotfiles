if status is-interactive

if command -q fastfetch
    fastfetch
else
    set fish_greeting
end

# Editor
set -gx EDITOR nvim
set -gx VISUAL nvim

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

# Config Shortcuts
abbr -a cdf 'cd ~/.config/fish && $EDITOR config.fish'
abbr -a cdk 'cd ~/.config/kitty && $EDITOR kitty.conf'
abbr -a cdw 'cd ~/.config/waybar && $EDITOR style.css'
abbr -a cdh 'cd ~/.config/hypr && $EDITOR moldules/decorations.lua'
abbr -a cds 'cd ~/.config && $EDITOR starship.toml'
abbr -a cdr 'cd ~/.config/rofi/type-1 && $EDITOR style-9.rosi'

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
abbr -a hpyr-log 'journalctl --user -u hyprland -f'

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
    mkdir =p $argv[1] && cd $argv[1]
end

# up N - go up N directories
function up -d "Go up N directories"
    set n (math (count $argv) > 0 ? $argv[1] : 1)
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
 
# hypr-wallpaper - set wallpaper via awww
function hypr-wallpaper -d "Set wallpaper with awww and a void-like transition"
    if not command -q awww
        echo "awww not found"
        return 1
    end
    awww img $argv[1] \
        --transition-type wipe \
        --transition-angle 270 \
        --transition-duration 2 \
        --transition-fps 60
end

end # end is-interactive

# Starship
starship init fish | source
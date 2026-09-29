# Abbreviations
# Unlike aliases, these expand in place when you press space or enter, so the
# full command shows up in your history and you can edit it before running.

if status is-interactive

    # --- Shell ---
    abbr -a refish 'exec fish'          # Restart fish to reload all config files
    abbr -a q 'exit'
    abbr -a c 'clear'
    abbr -a e '$EDITOR'
    abbr -a se 'sudo $EDITOR'

    # --- Navigation ---
    # (see also: `up N` for going up an arbitrary number of levels)
    abbr -a .. 'cd ..'
    abbr -a ... 'cd ../..'
    abbr -a .... 'cd ../../..'

    # --- Packages (yay / pacman) ---
    abbr -a y 'yay'
    abbr -a yi 'yay -S'                 # Install
    abbr -a yr 'yay -Rns'               # Remove with unused dependencies and configs
    abbr -a yu 'yay -Syu'               # Full system upgrade
    abbr -a yq 'yay -Q'                 # List installed packages
    abbr -a ys 'yay -Ss'                # Search repos and AUR
    abbr -a yqs 'yay -Qs'               # Search installed packages
    abbr -a ysy 'yay -Sy'               # Synchronize local package databases
    abbr -a mirrors 'sudo reflector --country US --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist'

    # --- Git: basics ---
    abbr -a g 'git'
    abbr -a ga 'git add'
    abbr -a gaa 'git add -A'
    abbr -a gc 'git commit'
    abbr -a gcm --set-cursor 'git commit -m "%"'    # Cursor lands between the quotes
    abbr -a gp 'git push'
    abbr -a gfp 'git fetch origin --prune && git pull'

    # --- Git: branches and stash ---
    abbr -a gco 'git checkout'
    abbr -a gcb 'git checkout -b'
    abbr -a gb 'git branch'
    abbr -a gba 'git branch --all'
    abbr -a gbd 'git branch -d'         # Delete a merged branch
    abbr -a gbD 'git branch -D'         # Force delete
    abbr -a gst 'git stash'
    abbr -a gsp 'git stash pop'

    # --- Git: status and diff ---
    abbr -a gs 'git status'
    abbr -a gss 'git status --short --branch'
    abbr -a gd 'git diff'
    abbr -a gds 'git diff --staged'
    abbr -a gdc 'git diff --cached'     # Same as gds (--cached is the older spelling)

    # --- Git: history ---
    abbr -a glast 'git log -1 HEAD'
    abbr -a gshow 'git show --stat'
    abbr -a gl 'git log --oneline --graph --decorate'
    abbr -a glog 'git log --graph --all --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)%an%C(reset) %C(bold yellow)%s%C(reset)"'

    # --- Git: remotes ---
    abbr -a gr 'git remote -v'
    abbr -a gfetch 'git fetch --all --prune'

    # --- Git: undo ---
    abbr -a gunstage 'git restore --staged'
    abbr -a gdiscard 'git restore'      # Discards working tree changes, be careful

    # --- Python ---
    abbr -a mkvenv 'python -m venv venv && source venv/bin/activate.fish'
    abbr -a pipu 'pip install --upgrade pip'

    # --- Hyprland ---
    abbr -a hypr-reload 'hyprctl reload'
    abbr -a hypr-log 'journalctl --user -u hyprland -f'

    # --- Notifications (SwayNC) ---
    abbr -a swaync-reload 'swaync-client --reload-config'

    # --- System info ---
    abbr -a ff 'fastfetch'

    # --- Apps launched in the background ---
    abbr -a razer 'polychromatic-controller & disown'
    abbr -a obsidian 'flatpak run md.obsidian.Obsidian & disown'
    abbr -a obs-studio 'flatpak run com.obsproject.Studio & disown'

    # --- Custom functions ---
    abbr -a tp 'teleport'

end

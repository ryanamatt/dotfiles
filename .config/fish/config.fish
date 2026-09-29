# ~/.config/fish/config.fish
#
# Entry point. Kept small on purpose; fish loads the rest automatically.
#
#   conf.d/00-env.fish             Environment variables and PATH
#   conf.d/10-abbreviations.fish   All abbreviations, grouped by topic
#   conf.d/20-venv.fish            Auto activate/deactivate Python virtualenvs
#   conf.d/30-notify.fish          Desktop notification for slow commands
#   functions/                     One file per function
#   completions/                   Custom tab completions
#
# Load order: conf.d/*.fish (alphabetical), then this file.

if status is-interactive
    set -g fish_greeting ""

    if test "$TERM_PROGRAM" != vscode
        command -q fastfetch; and fastfetch

        # Starship prompt
        command -q starship; and starship init fish | source

        # If VS Code is open on this Hyprland workspace, start in its directory
        vscode_open_cwd
    end
end

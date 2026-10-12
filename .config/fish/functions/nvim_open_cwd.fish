function nvim_open_cwd -d "cd to the directory of the Neovim window on the current Hyprland workspace"
    # Called once at shell startup (see config.fish). If a terminal running
    # Neovim is on the same workspace as this terminal, cd into the working
    # directory shown in its title bar.
    #
    # Requirements: Hyprland (hyprctl) and jq.
    # This assumes Neovim sets the terminal title to "nvim: <cwd>", so add
    #   vim.opt.title = true
    #   vim.opt.titlestring = "nvim: %{getcwd()}"
    # to your Neovim config. The "nvim: " prefix is what lets this function
    # tell a Neovim window apart from any other terminal, whatever terminal
    # emulator you use.

    # Not running under Hyprland, or jq missing: nothing to do
    test -n "$HYPRLAND_INSTANCE_SIGNATURE"; or return 0
    command -q jq; or return 0

    # Inside Neovim's own :terminal: nothing to do
    set -q NVIM; and return 0

    # ID of the workspace this terminal is on
    set -l active_workspace (hyprctl activeworkspace -j | jq -r '.id' 2>/dev/null)

    # Title of the first Neovim window on that workspace
    set -l nvim_title (hyprctl clients -j | jq -r --arg ws "$active_workspace" 'first(.[] | select((.title | startswith("nvim: ")) and (.workspace.id == ($ws | tonumber))) | .title)' 2>/dev/null)

    if test -n "$nvim_title"; and test "$nvim_title" != null
        # Strip the "nvim: " prefix and surrounding whitespace
        set -l clean_path (string replace -r '^nvim:\s*' '' $nvim_title)
        set clean_path (string trim $clean_path)

        # Expand a leading ~ to $HOME
        set -l expanded_path (string replace -r '^~' "$HOME" $clean_path)

        if test -d "$expanded_path"; and test "$expanded_path" != "$PWD"
            cd "$expanded_path"
        end
    end
end
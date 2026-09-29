function vscode_open_cwd -d "cd to the directory of the VS Code window on the current Hyprland workspace"
    # Called once at shell startup (see config.fish). If a VS Code window is on
    # the same workspace as this terminal, cd into the directory of the file or
    # folder shown in its title bar.
    #
    # Requirements: Hyprland (hyprctl) and jq.
    # This assumes the VS Code window title is a path, so set
    #   "window.title": "${activeEditorLong}"   (or similar)
    # in VS Code. With the default title format it will simply find nothing.

    # Not running under Hyprland, or jq missing: nothing to do
    test -n "$HYPRLAND_INSTANCE_SIGNATURE"; or return 0
    command -q jq; or return 0

    # ID of the workspace this terminal is on
    set -l active_workspace (hyprctl activeworkspace -j | jq -r '.id' 2>/dev/null)

    # Title of the first VS Code window on that workspace
    set -l vscode_title (hyprctl clients -j | jq -r --arg ws "$active_workspace" 'first(.[] | select(.class == "com.microsoft.VSCode" and (.workspace.id == ($ws | tonumber))) | .title)' 2>/dev/null)

    if test -n "$vscode_title"; and test "$vscode_title" != null
        # Strip a leading dirty indicator (● or *) and surrounding whitespace
        set -l clean_path (string replace -r '^[●\*\s]+' '' $vscode_title)
        set clean_path (string trim $clean_path)

        # Expand a leading ~ to $HOME
        set -l expanded_path (string replace -r '^~' "$HOME" $clean_path)

        # A file means "its parent directory"; a directory means itself
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

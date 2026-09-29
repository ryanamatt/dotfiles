function teleport -d "Bookmark directories with short tags and jump back to them"
    # Usage:
    #   teleport <tag>          cd to the directory saved under <tag>
    #   teleport add <tag>      save the current directory as <tag> (overwrites)
    #   teleport list           show all bookmarks
    #   teleport remove <tag>   delete one bookmark
    #   teleport clear          delete all bookmarks
    #
    # Bookmarks are stored in $TELEPORT_FILE (see conf.d/00-env.fish), one
    # "<tag> <path>" pair per line. Tags must not contain spaces.
    set -l tp_file $HOME/.config/.teleport_bookmarks
    set -q TELEPORT_FILE; and set tp_file $TELEPORT_FILE

    # Make sure the storage file exists
    touch "$tp_file"

    switch "$argv[1]"
        case add
            if test -z "$argv[2]"
                echo -e "\033[0;31mError:\033[0m Please provide a tag name. Usage: teleport add [tag]"
            else
                # Drop any existing entry for this tag so tags stay unique
                sed -i "/^$argv[2] /d" "$tp_file"
                echo "$argv[2] $PWD" >> "$tp_file"
                echo -e "\033[0;32mTagged:\033[0m $argv[2] -> $PWD"
            end

        case list
            echo -e "\033[0;34mTeleport Bookmarks:\033[0m"
            echo -e "\033[0;36mName   Bookmark\033[0m"
            if test ! -s "$tp_file"
                echo "No tags saved yet."
            else
                column -t -s ' ' "$tp_file"
            end

        case remove
            if test -z "$argv[2]"
                echo -e "\033[0;31mError:\033[0m Specify a tag to remove."
            else
                sed -i "/^$argv[2] /d" "$tp_file"
                echo -e "\033[0;32mRemoved tag:\033[0m $argv[2]"
            end

        case clear
            true > "$tp_file"
            echo -e "\033[0;31mAll bookmarks cleared.\033[0m"

        case ""
            echo -e "\033[0;34mUsage:\033[0m teleport [tag | add <tag> | list | remove <tag> | clear]"

        case "*"
            # Default action: treat the argument as a tag and jump to it
            set -l target (grep "^$argv[1] " "$tp_file" | cut -d' ' -f2-)
            if test -d "$target"
                echo -e "\033[0;32mTeleporting to:\033[0m $target"
                cd "$target"
            else
                echo -e "\033[0;31mError:\033[0m Tag '$argv[1]' not found or directory no longer exists."
                return 1
            end
    end
end

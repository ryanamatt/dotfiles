# Tab completion for `teleport`

# Print "<tag>\t<path>" for each saved bookmark so the path shows as the description
function __teleport_tags
    set -l tp_file $HOME/.config/.teleport_bookmarks
    set -q TELEPORT_FILE; and set tp_file $TELEPORT_FILE
    test -f "$tp_file"; or return

    while read -l tag dir
        printf '%s\t%s\n' $tag $dir
    end <"$tp_file"
end

complete -c teleport -f

# First argument: a subcommand or a bookmark tag
complete -c teleport -n __fish_use_subcommand -a add -d "Bookmark the current directory as <tag>"
complete -c teleport -n __fish_use_subcommand -a list -d "Show all bookmarks"
complete -c teleport -n __fish_use_subcommand -a remove -d "Delete one bookmark"
complete -c teleport -n __fish_use_subcommand -a clear -d "Delete all bookmarks"
complete -c teleport -n __fish_use_subcommand -a '(__teleport_tags)'

# `teleport remove <tab>` completes existing tags
complete -c teleport -n '__fish_seen_subcommand_from remove' -a '(__teleport_tags)'

function wtree -d "Show the Wisp project tree, hiding docs, .git, build and assets"
    # Usage: wtree [extra tree options]
    # Lists hidden files, appends / to directories, and puts files before
    # directories. Prints the underlying tree command first so it is easy to copy.
    set -l exclude "docs|.git|build|assets"

    echo "tree -aIF '$exclude' --filesfirst $argv"
    tree -aIF "$exclude" --filesfirst $argv
end

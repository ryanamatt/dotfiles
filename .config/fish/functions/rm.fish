# see bin/trash.py for trash script.

function rm --description 'Move files to ~/.trash instead of deleting them'
    set -l args
    for arg in $argv
        switch $arg
            case -r -R -f -rf -fr -Rf -fR
                continue
            case '*'
                set -a args $arg
        end
    end

    trash $args
end
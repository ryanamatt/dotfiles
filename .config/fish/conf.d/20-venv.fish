# Python virtualenv auto-switching
#
# This lives in conf.d (not functions/) because it is an event handler:
# fish only registers --on-variable handlers once the file has been loaded,
# and autoloaded functions are not loaded until first called.

function auto_activate_venv --on-variable PWD -d "Activate ./.venv or ./venv when entering a project, deactivate when leaving"
    # Pick whichever venv directory exists (.venv takes priority)
    set -l venv_dir
    for candidate in .venv venv
        if test -f $candidate/bin/activate.fish
            set venv_dir $candidate
            break
        end
    end

    if test -n "$venv_dir"
        # Only source the activate script if this venv is not already active
        if not string match -q "$PWD/$venv_dir*" "$VIRTUAL_ENV"
            source $venv_dir/bin/activate.fish
            echo -e "\e[32m(V) Activated Virtual Environment\e[0m"
        end
    else if test -n "$VIRTUAL_ENV"; and functions -q deactivate
        # No venv in this directory but one is still active: turn it off
        deactivate
        echo -e "\e[31m(V) Deactivated Virtual Environment\e[0m"
    end
end

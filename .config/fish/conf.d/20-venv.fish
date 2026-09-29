# Python virtualenv auto-switching
#
# This lives in conf.d (not functions/) because it is an event handler:
# fish only registers --on-variable handlers once the file has been loaded,
# and autoloaded functions are not loaded until first called.

function auto_activate_venv --on-variable PWD -d "Activate ./venv when entering a project, deactivate when leaving"
    if test -d venv
        # Only source the activate script if this venv is not already active
        if not string match -q "$PWD/venv*" "$VIRTUAL_ENV"
            source venv/bin/activate.fish
            echo -e "\e[32m(V) Activated Virtual Environment\e[0m"
        end
    else if test -n "$VIRTUAL_ENV"; and functions -q deactivate
        # No venv in this directory but one is still active: turn it off
        deactivate
        echo -e "\e[31m(V) Deactivated Virtual Environment\e[0m"
    end
end

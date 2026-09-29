function mkcd -d "Create a directory (and parents) and cd into it"
    # Usage: mkcd <dir>
    if test (count $argv) -ne 1
        echo "Usage: mkcd <directory>"
        return 1
    end

    mkdir -p -- "$argv[1]"; and cd -- "$argv[1]"
end

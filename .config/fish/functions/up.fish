function up -d "Go up N directories (default 1)"
    # Usage: up [N]
    # Examples:
    #   up      same as cd ..
    #   up 3    same as cd ../../..
    set -l n 1
    if test (count $argv) -gt 0
        set n $argv[1]
    end

    if string match -rq '^[1-9][0-9]*$' -- "$n"
        cd (string repeat -n $n '../')
    else
        echo "Usage: up [positive number]"
        return 1
    end
end

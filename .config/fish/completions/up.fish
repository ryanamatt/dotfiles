# Tab completion for `up`
#
# Offers 1, 2, 3... with the directory each one would take you to, stopping
# at the filesystem root. Example when in ~/dev/wisp/src:
#   1  ~/dev/wisp
#   2  ~/dev
#   3  ~
#   4  /home
#   5  /

function __up_levels
    set -l dir $PWD
    set -l home_re '^'(string escape --style=regex -- $HOME)

    for n in (seq 1 12)
        set dir (path dirname $dir)
        printf '%s\t%s\n' $n (string replace -r -- $home_re '~' $dir)
        test "$dir" = /; and break
    end
end

complete -c up -f
complete -c up -n __fish_is_first_arg -a '(__up_levels)'

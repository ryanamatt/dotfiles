# Tab completion for `bak`
#
# Takes exactly one path (file or directory), so normal file completion is
# used for the first argument and switched off afterwards.

complete -c bak -n 'not __fish_is_first_arg' -f

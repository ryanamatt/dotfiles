# Tab completion for `mkcd`
#
# Takes exactly one directory. Existing directories are offered so you can
# build on an existing path (mkcd projects/new-thing), but files are not.

complete -c mkcd -f
complete -c mkcd -n __fish_is_first_arg -a '(__fish_complete_directories)'

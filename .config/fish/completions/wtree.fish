# Tab completion for `wtree`
#
# wtree forwards its arguments straight to `tree` (after its own fixed
# options), so borrow tree's completions for flags and directories.

complete -c wtree -w tree

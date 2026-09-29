# Tab completion for `extract`
#
# Only offers directories (so you can navigate) and files with an extension
# the `extract` function knows how to handle. Matching is case sensitive to
# mirror the `switch` in functions/extract.fish, so keep the two in sync.

function __extract_candidates
    # __fish_complete_path prints "<path>\t<description>"; directories end in "/"
    __fish_complete_path (commandline -ct) | string match -r -- '^[^\t]*(/|\.(tar|tgz|tbz2|gz|bz2|zst|zip|7z))(\t|$)'
end

complete -c extract -f
complete -c extract -n __fish_is_first_arg -a '(__extract_candidates)'

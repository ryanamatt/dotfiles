# Tab completion for `orp` (Orpheus terminal text editor)
#
# Usage: orp [-t template] [file ...]
# File names complete normally, so no global "-f" is set here.

# Print the name of each template in ~/.config/Orpheus/templates (without the .tmpl suffix)
function __orp_templates
    set -l dir $HOME/.config/Orpheus/templates
    test -d "$dir"; or return

    for tmpl in $dir/*.tmpl
        test -f "$tmpl"; and path basename --no-extension -- $tmpl
    end
end

complete -c orp -s h -l help -f -d "Show help"
complete -c orp -s v -l version -f -d "Show version information"

# -t / --template NAME: template applied to any NEW file (or the new buffer if no file is given)
complete -c orp -s t -l template -r -f -a '(__orp_templates)' -d "Populate new files from a template"

# --gen-config [PATH]: PATH is optional, so files are still offered
complete -c orp -l gen-config -d "Write a commented default config file"

function bak -d "Rename a file or directory to <name>.bak-YYYY-MM-DD"
    # Usage: bak <path>
    # Example: bak config.toml  ->  config.toml.bak-2026-09-28
    # Refuses to overwrite an existing backup from the same day.
    if test (count $argv) -ne 1
        echo "Usage: bak <path>"
        return 1
    end

    set -l file "$argv[1]"
    set -l date (date '+%Y-%m-%d')
    set -l backup "$file.bak-$date"

    if test -e "$backup"
        echo "'$backup' already exists"
        return 1
    end

    mv -- "$file" "$backup"
end

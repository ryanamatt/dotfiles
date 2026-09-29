function extract -d "Extract an archive, picking the right tool from the file extension"
    # Usage: extract <archive>
    # Supports: tar (.tar .tar.gz .tgz .tar.bz2 .tbz2 .tar.xz .tar.zst),
    #           .gz .bz2 .zst, .zip, .7z
    # Extracts into the current directory.
    set -l archive $argv[1]

    if test -z "$archive"
        echo "Usage: extract <archive>"
        return 1
    end

    if not test -f "$archive"
        echo "'$archive' is not a file"
        return 1
    end

    switch $archive
        case '*.tar.bz2' '*.tbz2'
            tar xjf $archive
        case '*.tar.gz' '*.tgz'
            tar xzf $archive
        case '*.tar.xz'
            tar xJf $archive
        case '*.tar.zst'
            tar --use-compress-program=unzstd -xf $archive
        case '*.tar'
            tar xf $archive
        case '*.bz2'
            bunzip2 $archive
        case '*.gz'
            gunzip $archive
        case '*.zst'
            unzstd $archive
        case '*.zip'
            unzip $archive
        case '*.7z'
            7z x $archive
        case '*'
            echo "'$archive' cannot be extracted: unknown format"
            return 1
    end
end

#!/usr/bin/awk -f

# Usage: ./peek [file]
# Simple previewer for text, images, and metadata

BEGIN {
    if (ARGC < 2) {
        print "Usage: peek <filename>"
        exit 1
    }
    file = ARGV[1]
    
    # Check if file exists
    if (getline < file == -1) {
        print "Error: Cannot open file '" file "'"
        exit 1
    }
    close(file)

    # Detect Type by Extension
    split(file, ext, ".")
    type = tolower(ext[length(ext)])

    print "--- Preview: " file " ---"

    if (type ~ /txt|md|py|sh|c|cpp|nim|toml/) {
        # Preview first 5 lines of text files
        system("head -n 5 " file)
    } 
    else if (type ~ /jpg|jpeg|png|gif/) {
        # Requires 'identify' from ImageMagick
        system("identify " file " 2>/dev/null || echo 'Install ImageMagick for image dimensions.'")
    }
    else if (type ~ /mp3|wav|flac|ogg/) {
        # Requires 'ffprobe' from ffmpeg
        system("ffprobe -v error -show_entries format=duration,format_name -of default=noprint_wrappers=1:nokey=1 " file " 2>/dev/null || echo 'Install ffmpeg for audio metadata.'")
    }
    else {
        print "File type '" type "' not supported for preview."
    }
}
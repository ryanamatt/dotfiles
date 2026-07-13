#!/usr/bin/awk -f
#
# Scans files/directories for TODO/FIXME/NOTE comments and prints a report.
#
# Usage:
#   ./lint-notes.awk
#   ./lint-notes.awk src/
#   ./lint-notes.awk file1.c file2.py
#   ./lint-notes.awk src lib main.c
#
# If no arguments are given, scans the current directory.

BEGIN {
    # Tags to search for
    tag_re = "(TODO|FIXME|NOTE)"

    # if no args given, scan cwd
    if (ARGC <= 1) {
        scan(".")
    } else {
        for (i = 0; i < ARGC; i++) {
            scan(ARGV[i])
        }
    }

    print_report()
    exit
}

# Recursively Scan a path
function scan(path, cmd, line, type) {
    # Determine if path is fore or directory
    cmd = "test -d \"" path "\" && echo dir || echo file"

    cmd | getline type
    close(cmd)

    if (type == "dir") {
        scan_dir(path)
    } else {
        scan_file(path)
    }
}

# Scan a directory recursively
function scan_dir(dir,    cmd, file) {
    cmd = "find \"" dir "\" -type f 2>/dev/null"

    while ((cmd | getline file) > 0) {
        scan_file(file)
    }

    close(cmd)
}

# Scan a single file
function scan_file(file,    line, n, tag, text) {
    while ((getline line < file) > 0) {
        if (match(line, tag_re)) {
            tag = substr(line, RSTART, RLENGTH)

            text = line
            sub(/^.*(TODO|FIXME|NOTE)[: ]*/, "", text)

            count[tag]++
            total++

            results[++idx] = sprintf("%-6s | %s:%d | %s", tag, file, FNR + 0, text)
        }

        FNR++
    }

    close(file)
    FNR = 0
}

# Print final report
function print_report(    i) {
    print "=== lint-notes report ==="
    print ""

    print "Summary:"
    printf("  TODO : %d\n", count["TODO"] + 0)
    printf("  FIXME: %d\n", count["FIXME"] + 0)
    printf("  NOTE : %d\n", count["NOTE"] + 0)
    printf("  TOTAL: %d\n", total + 0)

    print ""
    print "Findings:"
    print "------------------------------------------------------------"

    for (i = 1; i <= idx; i++) {
        print results[i]
    }
}
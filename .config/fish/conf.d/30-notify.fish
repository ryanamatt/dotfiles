# Long-running command notifications
#
# Event handler, so it lives in conf.d (see the note in 20-venv.fish).

function notify_long --on-event fish_postexec -d "Send a desktop notification when a command runs longer than 30 seconds"
    set -l threshold_ms 30000

    set -l ignored_commands nano vim nvim less man orp

    set -l base_cmd (string split -f 1 " " $argv[1])

    # Only notify if the command is not in the ignored list and exceeds the threshold
    if not contains -- $base_cmd $ignored_commands; and test $CMD_DURATION -gt $threshold_ms; and command -q notify-send
        # fish_postexec passes the command line that just finished as $argv[1]
        notify-send -a fish "Command finished" "$argv[1] took "(math -s0 $CMD_DURATION / 1000)"s"
    end
end

# Tab completion for `wisp` (Quickshell based bar/shell for Hyprland)
#
# Usage: wisp [command] [options]
# The IPC target list below is hardcoded.

# --- IPC targets accepted by open / close / toggle ---
set -g __wisp_targets calendar appLauncher powerMenu audioPlayer systemMonitor clipboard network brightness battery themeSwitcher workspaceSwitcher commandCenter

# Print "<target>\t<description>" for each IPC target
function __wisp_target_descriptions
    printf '%s\t%s\n' \
        calendar "Calendar popup" \
        appLauncher "Application launcher" \
        powerMenu "Power menu" \
        audioPlayer "Audio player" \
        systemMonitor "System monitor" \
        clipboard "Clipboard manager" \
        network "Network panel" \
        brightness "Brightness control" \
        battery "Battery panel" \
        themeSwitcher "Theme switcher" \
        workspaceSwitcher "Workspace switcher" \
        commandCenter "Command center"
end

# True until a command (run, kill, ...) has been typed
function __wisp_needs_command
    not __fish_seen_subcommand_from run kill reload log open close toggle
end

# True after open/close/toggle, until a target has been typed
function __wisp_needs_target
    __fish_seen_subcommand_from open close toggle; or return 1
    not __fish_seen_subcommand_from $__wisp_targets
end

# True after `log`, until head/tail/clear has been typed
function __wisp_needs_log_action
    __fish_seen_subcommand_from log; or return 1
    not __fish_seen_subcommand_from head tail clear
end

# --- Commands ---
complete -c wisp -f -n __wisp_needs_command -a run -d "Launch the bar"
complete -c wisp -f -n __wisp_needs_command -a kill -d "Stop a running wisp instance"
complete -c wisp -f -n __wisp_needs_command -a reload -d "Restart the quickshell process of a running instance"
complete -c wisp -f -n __wisp_needs_command -a log -d "Print or manage log contents"
complete -c wisp -f -n __wisp_needs_command -a open -d "Open a widget or popup"
complete -c wisp -f -n __wisp_needs_command -a close -d "Close a widget or popup"
complete -c wisp -f -n __wisp_needs_command -a toggle -d "Toggle a widget or popup"

# --- log [head|tail|clear] [n] ---
complete -c wisp -f -n __wisp_needs_log_action -a head -d "Print the first n lines"
complete -c wisp -f -n __wisp_needs_log_action -a tail -d "Print the last n lines (default 15)"
complete -c wisp -f -n __wisp_needs_log_action -a clear -d "Empty the log"

# --- open / close / toggle <target> ---
complete -c wisp -f -n __wisp_needs_target -a '(__wisp_target_descriptions)'

# --- Options ---
complete -c wisp -s d -f -d "Disown: return to the shell and keep running detached"
complete -c wisp -s f -r -f -a '(__fish_complete_directories)' -d "Directory containing shell.qml"
complete -c wisp -s m -r -f -a '(__fish_complete_directories)' -d "Extra QML module import path"
complete -c wisp -s c -r -f -a '(__fish_complete_suffix .json)' -d "Path to config.json"
complete -c wisp -s h -l help -f -d "Show help"
complete -c wisp -s v -l version -f -d "Show version information"

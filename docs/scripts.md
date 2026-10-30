# Scripts

Quick reference for the custom scripts and functions in these dotfiles.

Scripts are symlinked without extension but extension is here to explain the language the script is made in.

## bin

Standalone scripts in `bin/`.

### count-tag-commits.sh
Prints the number of commits between each consecutive git tag (with tag dates), plus commits since the last tag and a grand total. Errors out if not in a repo or if there are no tags.

### dub.sh
Nicknames long commands. `dub add <name> <cmd>` saves one, `dub <name>` runs it (via `eval`), plus `list`, `remove <name>` and `clear`. Stored in `~/.config/.dub_aliases`.

### git-dual-commit.sh
Commits on the current branch, then cherry-picks that commit onto the other of `laptop`/`pc` and switches back. Pass `-p` to push both branches.

### keybinds.py
Parses `~/.config/hypr/modules/binds.lua` and prints the Hyprland keybinds grouped by the comments in the file. Takes an optional filter pattern, `-f` for a different file, and `--no-color`.

### lint-notes.awk
Scans files or directories (default: cwd) for `TODO`, `FIXME` and `NOTE` comments. Prints a count summary followed by each finding as `tag | file:line | text`.

### loc.py
Given files or directories counts the lines of codes. Groups by language and gives the output back to the user in a pretty format.

### peek.awk
Quick file previewer. Shows the first 5 lines of text files, dimensions for images (needs ImageMagick), and duration/format for audio (needs ffprobe).

### sprout.py
Project scaffolder for Python, C and C++. Creates the directory, venv or `src/include/build` layout, and optionally a Makefile, CMakeLists.txt, pyproject.toml, README and git repo. Rolls back on failure.

### trash.py
Moves files to `~/.trash` instead of deleting them, renaming on name collisions. `-p` deletes permanently, `-l` lists the trash, `-e` empties it (with confirmation).

### upkeep.sh
System maintenance for Arch. Runs `yay -Syu` and Flatpak updates, removes orphans and unused Flatpaks, clears package caches, then sends a Wisp desktop notification.

### wb.py
Opens a Google search for the given text, or opens the file in a browser if the argument is an existing path. Routes through PowerShell when running under WSL.

## fish

Functions in `.config/fish/functions/`.

### bak
Renames a file or directory to `<name>.bak-YYYY-MM-DD`. Refuses to overwrite a backup made the same day.

### extract
Extracts an archive into the current directory, choosing the tool from the extension (tar variants, gz, bz2, zst, zip, 7z).

### mkcd
`mkdir -p` a directory and `cd` into it.

### nvim_open_cwd
Runs at shell startup. If a Neovim window (title starting with `nvim: `) is on the same Hyprland workspace, `cd`s into the directory in its title. Needs `hyprctl` and `jq`.

### rm
Overrides `rm` to send files to `trash` instead. Strips `-r`/`-f` style flags before passing arguments along. See `bin/trash.py`.

### teleport
Directory bookmarks. `teleport <tag>` jumps to a saved directory, with `add <tag>`, `list`, `remove <tag>` and `clear`. Stored in `$TELEPORT_FILE` (default `~/.config/.teleport_bookmarks`).

### up
Goes up N directories (default 1). `up 3` is `cd ../../..`.

### vault
Toggles the gocryptfs vault: mounts `~/.vault` at `~/vault` if locked (auto-locks after 15 minutes idle), unmounts if unlocked.

### vscode_open_cwd
Runs at shell startup. If a VS Code window is on the same Hyprland workspace, `cd`s into the directory of the file or folder in its title bar. Needs `hyprctl`, `jq`, and a path-style `window.title` in VS Code.

### wtree
Runs `tree` on the Wisp project, hiding `docs`, `.git`, `build` and `assets`, with hidden files shown and files listed first. Echoes the full command first so it is easy to copy.


# dotfiles

Personal Hyprland (Wayland) rice: fish, kitty, starship, swaync, rofi,
Orpheus, quickshell, and a small YAML -> Jinja2 pipeline for generating
consistent color themes across all of them.

> [!Important]
> **Heads up:** this is tailored to my system, my usernames, my paths,
> and my exact package choices. It will very likely **not** work perfectly
> out of the box if you clone it -- expect to edit paths, swap tools I
> use for ones you have, and generally treat this as a reference rather
> than a drop-in install. MIT licensed, so do whatever you want with it.

## What's here

| Path | What it is |
|---|---|
| `install.sh` | Symlinks static configs (fish, kitty, hyprland, swaync, rofi, Orpheus) and everything in `bin/` into `~/.config` / `~/.local/bin`. Backs up any real file it would overwrite as `<file>.bak`. `-u`/`--uninstall` reverses it and restores backups. |
| `switcher.sh` | Swaps the *themed* files (the ones that differ per-theme -- kitty colors, hypr colors, swaync colors, starship, fish colors, quickshell colors, hyprlock) by symlinking `themes/<Name>/` into `~/.config` and `~/dotfiles/quickshell`. Also fires off a wallpaper change and reloads the running apps. |
| `change_wallpaper.sh` | Sets the wallpaper for a theme (or an arbitrary image path) and remembers the last one in `wallpapers/.current_wallpaper`. |
| `theme-references/*.yaml` | One YAML file per theme -- the single source of truth for that theme's palette, semantic roles, ANSI colors, glyphs, borders, etc. |
| `generate_theme.py` + `templates/` | Renders every theme YAML through a Jinja2 template per target config file. |
| `create_theme.sh <Name>` | Convenience wrapper: builds the `themes/<Name>/` directory skeleton, then calls `generate_theme.py`. |
| `themes/<Name>/` | Generated output per theme -- this is what `switcher.sh` actually symlinks from. Not hand-edited; regenerate it instead. |
| `bin/` | Misc personal scripts (battery, wallpaper cycling, note linting, teleport, etc.), installed as commands without their file extensions. Each script has usage info in a header comment at the top of its file -- check there before running one blind. |

`Orpheus` (config linked by `install.sh`) is a minimal terminal text
editor I wrote myself: [Orpheus](https://github.com/ryanamatt/Orpheus).

## Requirements

- Arch Linux + Hyprland (this assumes a Wayland/Hyprland setup -- things
  like `hyprctl`, `hypridle`, `hyprlock` are baked in).
- fish, kitty, starship, swaync, rofi, fastfetch, quickshell.
- Awww wallpaper Daemon
- Python 3 with `pyyaml` and `jinja2` -- **only** needed if you're
  regenerating themes with `create_theme.sh`; not needed just to switch
  between already-generated themes.
- `jq` and (optionally) `razer-cli` -- only used by `switcher.sh`'s
  Razer-lighting sync, which no-ops quietly if either is missing.

## Installing

```bash
git clone <this repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

This symlinks the static configs and `bin/` scripts, then runs
`./switcher.sh Arcane` to apply the default theme. Run
`./install.sh -u` to remove the symlinks and restore whatever `.bak`
files it made along the way.

## Switching themes

```bash
./switcher.sh Ferryman          # switch to a theme
./switcher.sh -l                # list available themes, marks the active one
./switcher.sh -c                # show the currently active theme
./switcher.sh -n Grotto         # dry run -- prints what would change, touches nothing
```

Switching only touches files that exist under `themes/<Name>/` -- it
never removes or overwrites anything else in `~/.config`. Any real
(non-symlink) file it would clobber gets backed up once as `<file>.bak`.

## Adding a new theme

1. Copy `theme-references/arcane.yaml` as a starting point, or write a
   new one by hand -- it's just palette hex values, semantic role
   mappings, ANSI colors, borders, and glyphs.
2. `./create_theme.sh <NewThemeName>` -- builds `themes/<NewThemeName>/`
   and renders all the templated configs from the YAML.
3. Drop an ASCII-art reference file into
   `themes/<NewThemeName>/.config/fastfetch/<name>.txt` by hand.
   **Note:** fastfetch's `config.jsonc` doesn't actually read this file
   -- the art gets manually flattened to one line and pasted directly
   into the config. The `.txt` is kept purely so the art is easy to
   find again later if you forget it.
4. `./switcher.sh <NewThemeName>` to activate it.

## License

MIT. See `LICENSE`.

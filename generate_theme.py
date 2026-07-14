#!/usr/bin/env python3
"""
generate_theme.py -- render a theme-reference YAML into every dotfile that
needs theme colors.

Usage:
    ./generate_theme.py theme-references/arcane.yaml
    ./generate_theme.py theme-references/arcane.yaml --out themes/Arcane

Design:
  - theme-references/<slug>.yaml is the single source of truth (replaces
    the old .txt reference docs -- keep writing the *concept* by hand in
    there, but colors/roles are now structured data).
  - templates/ holds one Jinja2 template per generated file, using the
    exact relative path it should land at under themes/<Name>/.
  - This script resolves every `semantic:` key to a concrete hex value
    (following palette -> derived -> extra lookups), builds a flat
    context, and renders every template into the output tree.
  - create_theme.sh should call this after it creates the directory
    skeleton (or this script can create directories itself -- see
    ensure_dirs()).
"""
import argparse
import shutil
import sys
from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader, StrictUndefined

SCRIPT_DIR = Path(__file__).resolve().parent
TEMPLATES_DIR = SCRIPT_DIR / "templates"


def fish_escape(value: str) -> str:
    """Escape a value the way fish's own `set -U` writes it into
    fish_variables: alphanumerics and underscore pass through untouched,
    everything else becomes \\xHH (one escape per byte). Confirmed
    against fish 4.8.0 docs/examples (e.g. '-' -> \\x2d, '.' -> \\x2e,
    '#' -> \\x23, ':' -> \\x3a)."""
    out = []
    for ch in str(value):
        if ch.isalnum() or ch == "_":
            out.append(ch)
        else:
            out.append("".join(f"\\x{b:02x}" for b in ch.encode("utf-8")))
    return "".join(out)


def hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
    h = hex_str.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class ColorRef:
    """A resolved color: behaves like a string (the hex) but carries
    convenience accessors for templates, e.g. {{ c.background.hex }},
    {{ c.background.rgb }}, {{ c.background.no_hash }}."""

    def __init__(self, name: str, hex_str: str):
        self.name = name
        self.hex = hex_str

    @property
    def no_hash(self) -> str:
        return self.hex.lstrip("#")

    @property
    def rgb(self) -> tuple[int, int, int]:
        return hex_to_rgb(self.hex)

    def rgb_str(self, sep=", ") -> str:
        return sep.join(str(v) for v in self.rgb)

    def rgba(self, alpha: float) -> str:
        r, g, b = self.rgb
        return f"rgba({r}, {g}, {b}, {alpha})"

    def hl(self, alpha: str = "ff") -> str:
        """Hyprland's own color format: rgba(RRGGBBAA) as one hex blob,
        e.g. magenta.hl('60') -> 'rgba(b00ea260)'. `alpha` is a 2-digit
        hex string so exact values (like the 0x60 glow alpha used
        throughout hyprlock.conf) round-trip exactly, with no float
        rounding through 0-1 alpha."""
        return f"rgba({self.no_hash}{alpha})"

    def argb(self, alpha: str = "ff") -> str:
        """Qt/QML color format: #AARRGGBB -- alpha comes FIRST, unlike
        Hyprland's RRGGBBAA. Used by quickshell's colors.json (e.g.
        magenta.argb('40') -> '#40b00ea2')."""
        return f"#{alpha}{self.no_hash}"

    def __str__(self):
        return self.hex

    def __repr__(self):
        return f"ColorRef({self.name!r}, {self.hex!r})"


def build_lookup(theme: dict) -> dict[str, str]:
    """Map every palette/derived/extra name -> hex string."""
    lookup = {}
    for section in ("palette", "derived"):
        for name, entry in (theme.get(section) or {}).items():
            lookup[name] = entry["hex"]
    for name, hex_str in (theme.get("extra") or {}).items():
        lookup[name] = hex_str
    return lookup


def resolve(theme: dict) -> dict:
    """Return a template-ready context: theme dict, but `semantic` values,
    `borders[*].color`, `glow.color`, `ansi[*].hex` etc. are ColorRef
    objects instead of bare names/strings."""
    lookup = build_lookup(theme)

    def ref(name: str) -> ColorRef:
        if name not in lookup:
            raise KeyError(
                f"'{name}' is not defined in palette/derived/extra"
            )
        return ColorRef(name, lookup[name])

    ctx = dict(theme)  # shallow copy

    # semantic: role -> ColorRef
    ctx["semantic"] = {k: ref(v) for k, v in theme["semantic"].items()}

    # ansi: list of {index, name, hex} -> keep hex as-is but also index by number
    ansi_by_index = {}
    for entry in theme.get("ansi", []):
        ansi_by_index[entry["index"]] = ColorRef(entry["name"], entry["hex"])
    ctx["ansi"] = theme.get("ansi", [])
    ctx["ansi_by_index"] = ansi_by_index

    # borders: resolve any key literally named "color"/"active"/"inactive"
    # that refers to a palette name into a ColorRef; leave numbers/strings.
    color_like_keys = {"color", "active", "inactive"}
    resolved_borders = {}
    for section, entry in (theme.get("borders") or {}).items():
        if isinstance(entry, dict):
            new_entry = dict(entry)
            for k in color_like_keys:
                if k in new_entry and isinstance(new_entry[k], str) and new_entry[k] in lookup:
                    new_entry[k] = ref(new_entry[k])
            resolved_borders[section] = new_entry
        else:
            resolved_borders[section] = entry
    ctx["borders"] = resolved_borders

    # glow.color
    if theme.get("glow"):
        glow = dict(theme["glow"])
        if glow.get("color") in lookup:
            glow["color"] = ref(glow["color"])
        ctx["glow"] = glow

    # raw palette/derived also available as ColorRef, for templates that
    # want a raw swatch directly (e.g. fastfetch logo color)
    ctx["palette"] = {
        name: ColorRef(name, entry["hex"])
        for name, entry in (theme.get("palette") or {}).items()
    }
    ctx["derived"] = {
        name: ColorRef(name, entry["hex"])
        for name, entry in (theme.get("derived") or {}).items()
    }

    return ctx


# Map template path (relative to templates/) -> output path
# (relative to themes/<Name>/), matching create_theme.sh's tree.
FILE_MAP = {
    ".config/fish/fish_variables.j2":                     ".config/fish/fish_variables",
    ".config/hypr/hyprlock.conf.j2":                      ".config/hypr/hyprlock.conf",
    ".config/hypr/modules/colors.lua.j2":                 ".config/hypr/modules/colors.lua",
    ".config/kitty/theme_colors.conf.j2":                 ".config/kitty/theme_colors.conf",
    ".config/starship.toml.j2":                           ".config/starship.toml",
    ".config/swaync/theme_colors.css.j2":                 ".config/swaync/colors/theme_colors.css",
    "quickshell/colors.json.j2":                          "quickshell/colors.json",
}


def ensure_dirs(out_dir: Path):
    for rel in FILE_MAP.values():
        (out_dir / rel).parent.mkdir(parents=True, exist_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("theme_yaml", type=Path, help="path to theme-references/<name>.yaml")
    parser.add_argument("--out", type=Path, default=None,
                         help="output dir, default themes/<Name> (relative to cwd)")
    parser.add_argument("--templates", type=Path, default=TEMPLATES_DIR,
                         help="templates directory (default: alongside this script)")
    args = parser.parse_args()

    theme = yaml.safe_load(args.theme_yaml.read_text())
    ctx = resolve(theme)

    out_dir = args.out or Path("themes") / theme["name"]
    ensure_dirs(out_dir)

    env = Environment(
        loader=FileSystemLoader(str(args.templates)),
        undefined=StrictUndefined,   # fail loudly on typos instead of silently emitting ""
        trim_blocks=True,
        lstrip_blocks=True,
        keep_trailing_newline=True,
    )
    env.filters["fish_escape"] = fish_escape

    written = []
    for tmpl_name, rel_out in FILE_MAP.items():
        tmpl_path = args.templates / tmpl_name
        if not tmpl_path.exists():
            print(f"  (skip) no template for {rel_out} ({tmpl_name} not found)", file=sys.stderr)
            continue
        template = env.get_template(tmpl_name)
        rendered = template.render(**ctx)
        dest = out_dir / rel_out
        dest.write_text(rendered)
        written.append(dest)

    print(f"Generated {len(written)} file(s) for theme '{theme['name']}' -> {out_dir}/")
    for f in written:
        print(f"  {f}")


if __name__ == "__main__":
    main()

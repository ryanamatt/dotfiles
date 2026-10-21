#!/usr/bin/env python3

"""keybinds: print Hyprland keybinds, grouped by the comments in binds.lua.

Usage:
    keybinds                 show everything
    keybinds wisp            show groups or lines matching "wisp"
    keybinds -f other.lua    read a different file
"""

import argparse
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

DEFAULT_FILE = "~/.config/hypr/modules/binds.lua"

# ---------------------------------------------------------------------------
# Display tables.
# ---------------------------------------------------------------------------

# Cleaned comment text (lowercase) -> group heading. Anything not listed is
# just uppercased, so "-- Game Mode" becomes "GAME MODE".
HEADING_OVERRIDES = {
    "example binds": "GENERAL",
    "move focus": "FOCUS",
    "switch workspaces": "WORKSPACES",
    "scroll through existing workspaces": "WORKSPACES",
    "move/resize windows": "MOUSE",
    "requires playerctl": "PLAYER",
}

# Raw key names -> friendlier names.
KEY_NAMES = {
    "grave": "`",
    "mouse:272": "Mouse Left",
    "mouse:273": "Mouse Right",
    "mouse_down": "Scroll Down",
    "mouse_up": "Scroll Up",
}

# Shell command regex -> short description. First match wins.
COMMAND_LABELS = [
    (r"hyprshutdown", "exit Hyprland"),
    (r"wpctl set-volume .*5%\+", "volume up"),
    (r"wpctl set-volume .*5%-", "volume down"),
    (r"wpctl set-mute @DEFAULT_AUDIO_SINK@", "toggle mute"),
    (r"wpctl set-mute @DEFAULT_AUDIO_SOURCE@", "toggle mic mute"),
    (r"brightnessctl set 5%\+", "brightness up"),
    (r"brightnessctl set 5%-", "brightness down"),
    (r"playerctl next", "next track"),
    (r"playerctl play-pause", "play/pause"),
    (r"playerctl previous", "previous track"),
]

# Matches both "wisp toggle runner" and the long dev-build form such as
# "/path/build/wisp -f /path/qml -m /path/qml toggle runner".
WISP_RE = re.compile(
    r"(?:^|/)wisp(?:\s+-\w\s+\S+)*\s+(?:toggle\s+(\w+)|(reload))\s*$"
)

# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------


@dataclass
class Entry:
    group: str
    keys: str
    desc: str


TOKEN_RE = re.compile(r'"([^"]*)"|\'([^\']*)\'|([A-Za-z_]\w*)')
LOCAL_RE = re.compile(r'^\s*local\s+(\w+)\s*=\s*"([^"]*)"')
BIND_RE = re.compile(r"(?<![\w.])hl\.bind\(")
FOR_RE = re.compile(r"^\s*for\s+\w+\s*=\s*(\d+)\s*,\s*(\d+)\s+do\b")
END_RE = re.compile(r"^\s*end\b")
DSP_RE = re.compile(r"^hl\.dsp\.([\w.]+)\((.*)\)\s*$", re.DOTALL)
FIELD_RE = re.compile(r'(\w+)\s*=\s*("[^"]*"|\w+)')


def eval_expr(expr, variables):
    """Evaluate a Lua string expression like: mainMod .. " + Return"."""
    out = []
    for m in TOKEN_RE.finditer(expr):
        if m.group(1) is not None:
            out.append(m.group(1))
        elif m.group(2) is not None:
            out.append(m.group(2))
        else:
            out.append(variables.get(m.group(3), m.group(3)))
    return "".join(out)


def scan_call_args(text, start):
    """Split call arguments, given the index just after the opening paren.

    Returns (args, end_index), or None if the call is not closed yet.
    """
    args, cur, depth, quote = [], [], 0, None
    i = start
    while i < len(text):
        ch = text[i]
        if quote:
            cur.append(ch)
            if ch == "\\" and i + 1 < len(text):
                cur.append(text[i + 1])
                i += 1
            elif ch == quote:
                quote = None
        elif text.startswith("--", i):
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        elif ch in "\"'":
            quote = ch
            cur.append(ch)
        elif ch in "([{":
            depth += 1
            cur.append(ch)
        elif ch in ")]}":
            if depth == 0:
                args.append("".join(cur).strip())
                return args, i
            depth -= 1
            cur.append(ch)
        elif ch == "," and depth == 0:
            args.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
        i += 1
    return None


def clean_heading(comment):
    text = comment.strip().rstrip(".:")
    text = re.split(r"\s+with\s+|,\s*|\s+for\s+", text, maxsplit=1)[0]
    text = re.sub(r"\s+bindings?$", "", text, flags=re.I)
    return HEADING_OVERRIDES.get(text.lower(), text.upper())


def format_keys(keys):
    parts = [p.strip() for p in keys.split("+")]
    return " + ".join(KEY_NAMES.get(p, p) for p in parts if p)


def describe_command(cmd):
    m = WISP_RE.search(cmd)
    if m:
        if m.group(2):
            return "reload wisp"
        return re.sub(r"(?<=[a-z])(?=[A-Z])", " ", m.group(1)).lower()
    for pattern, label in COMMAND_LABELS:
        if re.search(pattern, cmd):
            return label
    return cmd


def describe_workspace(ws):
    if ws == "e+1":
        return "next workspace"
    if ws == "e-1":
        return "previous workspace"
    return ws.removeprefix("name:")


def describe_action(action, variables, group):
    if action.startswith("function"):
        return f"{group.lower()} (Lua function)"
    m = DSP_RE.match(action)
    if not m:
        return action
    name, inner = m.group(1), m.group(2)
    fields = {k: v.strip('"') for k, v in FIELD_RE.findall(inner)}

    if name == "exec_cmd":
        return describe_command(eval_expr(inner, variables))
    if name == "window.close":
        return "close window"
    if name == "window.float":
        act = fields.get("action", "toggle")
        return "toggle floating" if act == "toggle" else f"float: {act}"
    if name == "window.drag":
        return "drag window"
    if name == "window.resize":
        return "resize window"
    if name == "focus":
        if "direction" in fields:
            return f"focus {fields['direction']}"
        if "workspace" in fields:
            ws = fields["workspace"]
            if ws in ("e+1", "e-1"):
                return describe_workspace(ws)
            return f"go to workspace {describe_workspace(ws)}"
    if name == "window.move" and "workspace" in fields:
        return f"move window to {describe_workspace(fields['workspace'])}"
    return f"{name}({inner})"


def parse(path):
    lines = Path(path).expanduser().read_text().splitlines()
    variables = {}
    entries = []
    group = "MISC"
    in_comment_run = False

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if not stripped:
            i += 1
            continue

        # Comments: banners are ignored, commented-out code is ignored, and
        # the first comment of a run becomes the group heading.
        if stripped.startswith("--"):
            body = stripped.lstrip("-").strip()
            is_banner = stripped.startswith("---") or not body
            if not is_banner and "(" not in body and not in_comment_run:
                group = clean_heading(body)
                in_comment_run = True
            i += 1
            continue

        in_comment_run = False

        m = LOCAL_RE.match(line)
        if m:
            variables[m.group(1)] = m.group(2)

        # Workspace loop: special-cased into two summary lines.
        m = FOR_RE.match(line)
        if m:
            lo, hi = m.group(1), m.group(2)
            mod = variables.get("mainMod", "SUPER")
            entries.append(Entry(group, f"{mod} + [1-0]", f"go to workspace {lo}-{hi}"))
            entries.append(
                Entry(group, f"{mod} + SHIFT + [1-0]", f"move window to workspace {lo}-{hi}")
            )
            while i < len(lines) and not END_RE.match(lines[i]):
                i += 1
            i += 1
            continue

        # A hl.bind(...) statement, possibly spanning several lines.
        m = BIND_RE.search(line)
        if m:
            text = line
            result = scan_call_args(text, BIND_RE.search(text).end())
            while result is None and i + 1 < len(lines):
                i += 1
                text += "\n" + lines[i]
                result = scan_call_args(text, BIND_RE.search(text).end())
            if result and len(result[0]) >= 2:
                args = result[0]
                keys = format_keys(eval_expr(args[0], variables))
                desc = describe_action(args[1], variables, group)
                entries.append(Entry(group, keys, desc))

        i += 1

    return entries


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------


def group_entries(entries):
    groups = {}
    for e in entries:
        groups.setdefault(e.group, []).append(e)
    return groups


def apply_filter(groups, pattern):
    if not pattern:
        return groups
    p = pattern.lower()
    result = {}
    for name, items in groups.items():
        if p in name.lower():
            result[name] = items
            continue
        hits = [e for e in items if p in e.keys.lower() or p in e.desc.lower()]
        if hits:
            result[name] = hits
    return result


def render(groups, color):
    def style(code, text):
        return f"\033[{code}m{text}\033[0m" if color else text

    shown = [e for items in groups.values() for e in items]
    if not shown:
        return ""
    width = max(len(e.keys) for e in shown)

    blocks = []
    for name, items in groups.items():
        rows = [style("1;36", name)]
        for e in items:
            pad = " " * (width - len(e.keys))
            rows.append(f"  {style('1', e.keys)}{pad}   {e.desc}")
        blocks.append("\n".join(rows))
    return "\n\n".join(blocks)


def main():
    ap = argparse.ArgumentParser(description="Show Hyprland keybinds.")
    ap.add_argument("pattern", nargs="?", help="only show groups or lines matching this text")
    ap.add_argument("-f", "--file", default=DEFAULT_FILE, help=f"binds file (default: {DEFAULT_FILE})")
    ap.add_argument("--no-color", action="store_true", help="disable colored output")
    args = ap.parse_args()

    path = Path(args.file).expanduser()
    if not path.is_file():
        print(f"keybinds: cannot read {path}", file=sys.stderr)
        return 1

    groups = apply_filter(group_entries(parse(path)), args.pattern)
    output = render(groups, color=sys.stdout.isatty() and not args.no_color and "NO_COLOR" not in os.environ)
    if not output:
        print("No matching keybinds.", file=sys.stderr)
        return 1
    print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())

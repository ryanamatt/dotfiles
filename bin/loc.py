#!/usr/bin/env python

"""
loc.py: Counts the lines of code in a file(s) or directories.
    Prints the output nicely and by languages.
"""

import argparse
from dataclasses import dataclass
import os
from pathlib import Path
import sys


LANGUAGE_MAP = {
    "python": [".py", ".pyw", ".ipynb"],
    "c": [".c", ".h"],
    "c++": [".cpp", ".hpp", ".cc", ".cxx", ".hh", ".hxx"],
    "bash": [".sh", ".bash"],
    "fish": [".fish"],
    "qml": [".qml", "qmldir"],
    "awk": [".awk"],
    "lua": [".lua"],
    "typescript": [".ts", ".tsx", ".mts", ".cts"],
    "javascript": [".js", ".jsx", ".mjs", ".cjs"],
    "rust": [".rs"],
    "go": [".go"],
    "java": [".java"],
    "html": [".html", ".htm"],
    "css": [".css", ".scss"],
    "sql": [".sql"],
    "zsh": [".zsh"],
}


extension_to_language = {
    ext: lang 
    for lang, exts in LANGUAGE_MAP.items() 
    for ext in exts
}


# ANSI styling used when printing.
RESET = "\033[0m"
STYLES = {
    "bold": "\033[1m",
    "dim": "\033[2m",
    "red": "\033[31m",
    "green": "\033[32m",
    "yellow": "\033[33m",
    "blue": "\033[34m",
    "magenta": "\033[35m",
    "cyan": "\033[36m",
    "white": "\033[37m",
    "bright_red": "\033[91m",
    "bright_green": "\033[92m",
    "bright_yellow": "\033[93m",
    "bright_blue": "\033[94m",
    "bright_magenta": "\033[95m",
    "bright_cyan": "\033[96m",
    "bright_white": "\033[97m",
}

LANGUAGE_COLORS = {
    "python": "blue",
    "c": "cyan",
    "c++": "magenta",
    "bash": "green",
    "zsh": "green",
    "fish": "bright_green",
    "qml": "bright_cyan",
    "awk": "bright_magenta",
    "lua": "bright_blue",
    "javascript": "yellow",
    "typescript": "bright_yellow",
    "rust": "red",
    "go": "bright_cyan",
    "java": "bright_red",
    "html": "bright_magenta",
    "css": "bright_blue",
    "sql": "bright_white",
}

UNKNOWN_LANGUAGE = "other"
MAX_PATH_WIDTH = 60
BAR_WIDTH = 20


@dataclass(frozen=True)
class CodeFile:
    path: Path
    language: str
    line_count: int


def _is_excluded(path: Path, exclude_paths: list[Path], resolved_excludes: list[Path]) -> bool:
    """
    Checks if a given path should be excluded based on exact match, parent directories, or folder names.

    Args:
        path: The path to see if its excluded.
        exclude_paths: The paths to exclude.
        resolved_excludes: The resolved excluded paths.

    Returns:
        True if should exclude path, False otherwise.
    """
    if any(part.startswith('.') and part not in ('.', '..') for part in path.parts):
        return True

    try:
        resolved_path = path.resolve()
    except OSError:
        resolved_path = path

    for exc, res_exc in zip(exclude_paths, resolved_excludes):
        if resolved_path == res_exc or res_exc in resolved_path.parents:
            return True
        if exc.name and any(part == exc.name for part in path.parts):
            return True
    return False


def _get_valid_files(paths: list[Path], exclude_paths: list[Path]) -> list[Path]:
    """
    Recursively collects all valid files from a list of paths (files or directories),
    respecting exclusions at any depth level.

    Args:
        paths: The list of Paths to check if there are valid files.
        exclude_paths: The list of Paths to exclude.

    Returns:
        The list of valid path files.
    """
    resolved_excludes = []
    for exc in exclude_paths:
        try:
            resolved_excludes.append(exc.resolve())
        except OSError:
            resolved_excludes.append(exc)

    files: list[Path] = []
    for path in paths:
        if _is_excluded(path, exclude_paths, resolved_excludes):
            continue
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            # Recursively find all files inside the directory, filtering out excluded ones
            for p in path.rglob("*"):
                if not _is_excluded(p, exclude_paths, resolved_excludes) and p.is_file():
                    files.append(p)
    return files


def _count_lines(path: Path) -> int:
    """
    Counts the lines in the valid file paths.

    Args:
        path: The file path.

    Returns:
        The number of lines the file. Returns -1 if an error in counting lines.
    """
    try:
        with open(path, 'r', encoding="utf-8") as file:
            return sum(1 for _ in file)
    except (OSError, UnicodeDecodeError):
        # Unreadable or binary file
        return -1


def handle_code_files(paths: list[Path]) -> list[CodeFile]:
    """
    Creates the CodeFile dataclasses and populates them from the valid paths.

    Args:
        paths: The valid files paths.

    Returns:
        A list of CodeFile dataclasses containing all the logic needed.
    """
    code_files: list[CodeFile] = []
    for path in paths: 
        path_str: str = str(path)
         
        file_extension: str = path.suffix.lower()
        file_name: str = path.name.lower()

        language = extension_to_language.get(file_extension)
        if language is None:
            language = extension_to_language.get(file_name)
        if language is None:
            language = ""
        
        lines: int = _count_lines(path)

        code_files.append(CodeFile(path=path, language=language,line_count=lines))

    return code_files


def _supports_color() -> bool:
    """
    Decides whether ANSI colors should be used.
    Honors the NO_COLOR convention and disables color when output is piped.
    
    Returns:
        True if terminal supports color. Otherwise False.
    """
    if os.environ.get("NO_COLOR") is not None:
        return False
    if not sys.stdout.isatty():
        return False
    if os.name == "nt":
        # Empty system call switches on ANSI handling in modern Windows terminals
        os.system("")
    return True


def _paint(text: str, *styles: str, enabled: bool) -> str:
    """
    Wraps text in ANSI styles. Pad text BEFORE painting so alignment stays correct.

    Args:
        text: The text to wrap in ANSI styles.
        styles: The styles to wrap the text in.
        enabled: Whether or not color is enabled.

    Returns:
    """
    if not enabled or not styles:
        return text
    codes = "".join(STYLES[style] for style in styles)
    return f"{codes}{text}{RESET}"


def _display_path(path: Path) -> str:
    """
    Shortens a path for display: relative to the cwd when possible,
    and truncated from the left if it is too long.

    Args:
        The Path to shorten.

    Returns:
        A str of the shortened path.
    """
    try:
        text = str(path.resolve().relative_to(Path.cwd().resolve()))
    except ValueError:
        text = str(path)
    if len(text) > MAX_PATH_WIDTH:
        text = "…" + text[-(MAX_PATH_WIDTH - 1):]
    return text


def _bar(value: int, total: int, color: str, enabled: bool) -> str:
    """
    Builds a small horizontal bar showing value as a share of total.
    
    Args:
        value: The value on the bar.
        total: The total value of the bar.
        color: The color of the value on the bar.
        enabled: Whether color is enabled.

    Returns:
        The str of the bar.
    """
    fraction = value / total if total else 0
    filled = round(fraction * BAR_WIDTH)
    if value > 0:
        filled = max(filled, 1)
    full = _paint("█" * filled, color, enabled=enabled)
    empty = _paint("░" * (BAR_WIDTH - filled), "dim", enabled=enabled)
    return full + empty


def _group_by_language(code_files: list[CodeFile]) -> dict[str, list[CodeFile]]:
    """
    Groups files by language. Files in each group are sorted by line count (largest first),
    and groups are ordered by their total line count (largest first).
    
    Args:
        code_files: The list of code files.

    Returns:
        A dict of the files by their language.
    """
    groups: dict[str, list[CodeFile]] = {}
    for code_file in code_files:
        language = code_file.language or UNKNOWN_LANGUAGE
        groups.setdefault(language, []).append(code_file)

    for files in groups.values():
        files.sort(key=lambda cf: cf.line_count, reverse=True)

    return dict(
        sorted(
            groups.items(),
            key=lambda item: sum(cf.line_count for cf in item[1]),
            reverse=True,
        )
    )


def _print_language_section(
    language: str,
    files: list[CodeFile],
    path_width: int,
    use_color: bool,
    n_entries: int | None,
) -> None:
    """
    Prints the heading and per-file rows for a single language.

    Args:
        language: The language of the group.
        files: The list of files in the group.
        path_width: The width of the path.
        use_color: Whether or not to use color.
        n_entries: The number of entries to print for each group. If None, print all.
    """
    color = LANGUAGE_COLORS.get(language, "white")
    total = sum(cf.line_count for cf in files)
    
     # Apply the --top slice here (files are already sorted by line_count descending)
    displayed_files = files[:n_entries] if n_entries is not None else files
    
    number_width = len(f"{max(cf.line_count for cf in files):,}")

    file_word = "file" if len(files) == 1 else "files"
    heading = _paint(language.upper(), "bold", color, enabled=use_color)
    details = _paint(
        f"({len(files)} {file_word}, {total:,} lines)", "dim", enabled=use_color
    )
    print(f"{heading} {details}")

    for code_file in displayed_files:
        path_text = _paint(
            f"{_display_path(code_file.path):<{path_width}}", enabled=use_color
        )
        lines_text = _paint(
            f"{code_file.line_count:>{number_width},}", "bold", enabled=use_color
        )
        bar = _bar(code_file.line_count, total, color, use_color)
        print(f"  {path_text}  {lines_text}  {bar}")
    print() 


def _print_summary(
    groups: dict[str, list[CodeFile]],
    grand_total: int,
    total_files: int,
    use_color: bool,
) -> None:
    """
    Prints the summary table with one row per language and a grand total.
    
    groups: The groups of the code files.
    grand_total: The total number of lines.
    total_files: The total number of files.
    use_color: Whether or not to use color.
    """
    rows = [
        (language, len(files), sum(cf.line_count for cf in files))
        for language, files in groups.items()
    ]

    lang_width = max(len("Language"), *(len(row[0]) for row in rows))
    files_width = max(len("Files"), len(f"{total_files:,}"))
    lines_width = max(len("Lines"), len(f"{grand_total:,}"))

    header = (
        f"{'Language':<{lang_width}}  {'Files':>{files_width}}  "
        f"{'Lines':>{lines_width}}  {'Share':>6}"
    )
    rule_width = len(header) + 2 + BAR_WIDTH
    rule = _paint("─" * rule_width, "dim", enabled=use_color)

    print(_paint("SUMMARY", "bold", "yellow", enabled=use_color))
    print(_paint(header, "bold", enabled=use_color))
    print(rule)

    for language, file_count, line_count in rows:
        color = LANGUAGE_COLORS.get(language, "white")
        share = (line_count / grand_total * 100) if grand_total else 0
        name = _paint(f"{language:<{lang_width}}", color, enabled=use_color)
        bar = _bar(line_count, grand_total, color, use_color)
        print(
            f"{name}  {file_count:>{files_width},}  "
            f"{line_count:>{lines_width},}  {share:>5.1f}%  {bar}"
        )

    print(rule)
    total_label = _paint(f"{'Total':<{lang_width}}", "bold", enabled=use_color)
    total_numbers = _paint(
        f"{total_files:>{files_width},}  {grand_total:>{lines_width},}",
        "bold",
        "green",
        enabled=use_color,
    )
    print(f"{total_label}  {total_numbers}")


def print_code_files(code_files: list[CodeFile], n_entries: int | None) -> None:
    """
    Prints the Code Files to the terminal prettily.
    
    Args:
        code_files: The code files to print to the terminal.
        n_entries: The number of entries of each group to print. If None, print all.
    """
    use_color = _supports_color()

    readable = [cf for cf in code_files if cf.line_count >= 0]
    skipped = [cf for cf in code_files if cf.line_count < 0]

    print()
    if readable:
        groups = _group_by_language(readable)
        grand_total = sum(cf.line_count for cf in readable)

        # One shared path column width so every section lines up
        path_width = max(len(_display_path(cf.path)) for cf in readable)

        for language, files in groups.items():
            _print_language_section(language, files, path_width, use_color, n_entries)

        _print_summary(groups, grand_total, len(readable), use_color)
    else:
        print(_paint("No readable files to count.", "yellow", enabled=use_color))

    if skipped:
        print()
        count = len(skipped)
        word = "file" if count == 1 else "files"
        print(
            _paint(
                f"Skipped {count} unreadable or binary {word}:",
                "red",
                enabled=use_color,
            )
        )
        for code_file in skipped:
            print(
                _paint(f"  {_display_path(code_file.path)}", "dim", enabled=use_color)
            )
    print()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Count the lines of code in file(s) or directories and print it prettily."
    )

    parser.add_argument("files", nargs="+", type=str, help="The files or dirs to count.")

    parser.add_argument(
        "-e",
        "--exclude",
        nargs="*",
        default=[],
        type=str,
        help="Files or directories to exclude."
    )

    parser.add_argument(
        "-t",
        "--top",
        type=int,
        default=None,
        help="Display only the top N files/entries." 
    )

    args = parser.parse_args()

    input_paths = [Path(file) for file in args.files]
    exclude_paths = [Path(file) for file in args.exclude]
    checked_files = _get_valid_files(input_paths, exclude_paths)

    if not checked_files:
        print("Could not find any valid file(s) or directories.")
        sys.exit(1)

    code_files: list[CodeFile] = handle_code_files(checked_files)
    print_code_files(code_files, args.top)


if __name__ == "__main__":
    main()


#!/usr/bin/env python3

"""
trash.py - A trash script that moves files to $HOME/.trash
"""

import sys
import argparse
import shutil
import datetime
from pathlib import Path

TRASH_DIR = Path(Path.home() / ".trash")

def build_args() -> argparse.ArgumentParser:
    """
    Builds the Arg Parser.

    Returns:
        The Argparse Argument Parser.
    """
    parser: argparse.ArgumentParser = argparse.ArgumentParser(
        description="A Simple Trash CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("files", nargs="*", help="The files/directories to be sent to the trash.")
    parser.add_argument(
        "-p", "--permanent", action="store_true", help="Deletes files outright instead of sending to trash."
    )
    parser.add_argument(
        "-e", "--empty", action="store_true", help="Empties the trash directory."
    )
    parser.add_argument(
        "-l", "--list", action="store_true", help="List what is in the trash."
    )

    return parser

def run_trash(files: list[Path], is_permanent: bool = False) -> bool:
    """
    Runs the trash command

    Returns:
        True if runs successfully. False Otherwise.
    """
    has_errors: bool = False
    for file_str in files:
        file_path: Path = Path(file_str).absolute()

        if not file_path.exists() or file_path.is_symlink():
            print(f"Error: '{file_path}' could not be found.", file=sys.stderr)
            has_errors = True
            continue

        try:
            if is_permanent:
                if file_path.is_dir():
                    shutil.rmtree(file_path)
                else:
                    file_path.unlink()
                continue

            target_path: Path = TRASH_DIR / file_path.name
            if target_path.exists():
                timestamp: str = datetime.datetime.now().strftime("%Y%m%d_%H%M%S_%f")
                target_path = TRASH_DIR / f"{file_path.stem}_{timestamp}{file_path.suffix}"

            shutil.move(str(file_path), str(target_path))

        except Exception as e:
            print(f"Error processing '{file_path}': {e}", file=sys.stderr)
            has_errors = True

    if has_errors:
        return False
    return True

def run_empty() -> bool:
    """
    Empties the Trash Directory.

    Returns:
        True if runs successfully. False Otherwise.
    """
    confirmation_str: str = input("Are you sure you would like to empty the trash? [y/n]: ").lower()

    if confirmation_str == "y" or confirmation_str == "yes":
        try:
            for item in TRASH_DIR.iterdir():
                if item.is_dir():
                    shutil.rmtree(item)
                else:
                    item.unlink()

        except Exception as e:
            print(f"Error emptying the trash': {e}", file=sys.stderr)
            return False

    return True

def run_list() -> bool:
    """
    List what is in the trash directory.

    Returns:
        True if runs successfully. False Otherwise.
    """
    try: 
        for item in TRASH_DIR.iterdir():
            item_str: str = str(item.name)
            if item.is_dir():
                item_str += "/"

            print(item_str)

    except Exception as e:
        print(f"Error trying to list trash contents': {e}", file=sys.stderr)
        return False

    return True

def main() -> None:
    """
    The Main Function
    """
    try:
        TRASH_DIR.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(f"Error: Could not create trash directory: {e}", file=sys.stderr)
        sys.exit(1)

    parser = build_args()
    args: argparse.Namespace = parser.parse_args()
    has_errors: bool = False


    if not args.files and not (args.empty or args.list):
        parser.print_help()
        sys.exit(1)

    if args.files:
        if not run_trash(args.files, args.permanent):
            has_errors = True

    if args.empty:
        if not run_empty():
            has_errors = True

    if args.list:
        if not run_list():
            has_errors = True

    if has_errors:
        sys.exit(1)

if __name__ == "__main__":
    main()

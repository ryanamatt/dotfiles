#!/usr/bin/env python3

"""
sprout.py - A multi-language project scaffolding utility.

This script automates the creation of project structures for Python, C, and C++.
It handles directory creation, virtual environment setup, git initialization,
and generates boilerplate files like Makefiles, CMakeLists.txt, pyproject.toml,
and README.md.

Examples:
    sprout.py myapp --lang python --toml --git
    sprout.py mymodule --lang python --module --libs requests flask
    sprout.py engine --lang cpp --cmake --make --std 20 --git
    sprout.py tool --lang c --cmake --readme
"""

import os
import sys
import shutil
import argparse
import subprocess
from pathlib import Path

SUPPORTED_LANGS = ("python", "c", "cpp", "c++")

GITIGNORE_TEMPLATES: dict[str, str] = {
    "python": "__pycache__/\n*.py[cod]\n*$py.class\nvenv/\n.venv/\n.env\nbuild/\ndist/\n*.egg-info/\n",
    "c": "*.o\n*.obj\n*.out\nbuild/\ncmake-build-*/\nCMakeFiles/\nCMakeCache.txt\ncmake_install.cmake\n",
    "cpp": "*.o\n*.obj\n*.out\n*.exe\nbuild/\ncmake-build-*/\nCMakeFiles/\nCMakeCache.txt\ncmake_install.cmake\n",
}

DEFAULT_STD = {"c": "11", "cpp": "17"}


# ---------------------------------------------------------------------------
# Presentation helpers
# ---------------------------------------------------------------------------

class Ansi:
    """A tiny set of ANSI escape codes, auto-disabled when unsupported."""
    _ENABLED = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None

    GREEN = "\033[92m" if _ENABLED else ""
    BLUE = "\033[94m" if _ENABLED else ""
    YELLOW = "\033[93m" if _ENABLED else ""
    RED = "\033[91m" if _ENABLED else ""
    BOLD = "\033[1m" if _ENABLED else ""
    RESET = "\033[0m" if _ENABLED else ""


def info(msg: str) -> None:
    print(f"{Ansi.BLUE}➜{Ansi.RESET} {msg}")


def success(msg: str) -> None:
    print(f"{Ansi.GREEN}✔{Ansi.RESET} {msg}")


def warn(msg: str) -> None:
    print(f"{Ansi.YELLOW}⚠{Ansi.RESET} {msg}")


def error(msg: str) -> None:
    print(f"{Ansi.RED}✘{Ansi.RESET} {msg}", file=sys.stderr)


class ScaffoldError(RuntimeError):
    """Raised when a scaffolding step fails, to trigger cleanup in main()."""


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    """
    Runs a subprocess command, raising ScaffoldError with a clear message
    on failure instead of letting a raw traceback surface.
    """
    try:
        return subprocess.run(cmd, check=True, **kwargs)
    except FileNotFoundError:
        raise ScaffoldError(f"Command not found: {cmd[0]}. Is it installed and on your PATH?")
    except subprocess.CalledProcessError as e:
        raise ScaffoldError(f"Command failed ({' '.join(cmd)}): exit code {e.returncode}")


# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="🌱 Sprout - A Project Scaffolding Script",
        epilog=__doc__.split("Examples:")[-1] and "Examples:\n"
        "  sprout.py myapp --lang python --toml --git\n"
        "  sprout.py mymodule --lang python --module --libs requests flask\n"
        "  sprout.py engine --lang cpp --cmake --make --std 20 --git\n"
        "  sprout.py tool --lang c --cmake --readme\n",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # General Arguments
    parser.add_argument("name", help="The name of the project directory to create.")
    parser.add_argument(
        "-l", "--lang", default="python", choices=SUPPORTED_LANGS,
        help="The programming language to scaffold (default: python).",
    )
    parser.add_argument("-g", "--git", action="store_true", help="Initialize git and create .gitignore")
    parser.add_argument(
        "-b", "--branch", default="main",
        help="Initial git branch name, used only with --git (default: main).",
    )
    parser.add_argument("--readme", action="store_true", help="Generate a basic README.md")

    # Python Arguments
    py_group = parser.add_argument_group("Python options")
    py_group.add_argument("--toml", action="store_true", help="Generate a pyproject.toml")
    py_group.add_argument("--module", action="store_true", help="Create a nested name/package directory structure")
    py_group.add_argument("--libs", nargs="+", help="Space-separated list of libraries to install (e.g., requests flask)")
    py_group.add_argument("--no-venv", action="store_true", help="Skip creating a virtual environment")
    py_group.add_argument(
        "--python", default=sys.executable,
        help="Python interpreter to use when creating the venv (default: current interpreter).",
    )

    # C/C++ Arguments
    c_group = parser.add_argument_group("C/C++ options")
    c_group.add_argument("--make", action="store_true", help="Generate a basic Makefile for the C/C++ project.")
    c_group.add_argument("--cmake", action="store_true", help="Generate a CMakeLists.txt for the C/C++ project.")
    c_group.add_argument(
        "--cmake-min", default="3.15", metavar="VERSION",
        help="Minimum required CMake version, used only with --cmake (default: 3.15).",
    )
    c_group.add_argument(
        "--std", metavar="N",
        help="Language standard version (e.g. 11, 17, 20). Defaults to 11 for C and 17 for C++.",
    )

    return parser


def validate_args(args: argparse.Namespace, parser: argparse.ArgumentParser) -> None:
    """Catches invalid combinations/values before any files are touched."""
    name = args.name.strip()
    if not name or name in (".", ".."):
        parser.error("project name must be a non-empty, non-relative path segment.")

    lang = args.lang.lower()
    if lang == "python":
        if args.make or args.cmake:
            warn("--make/--cmake are ignored for Python projects.")
    else:
        if args.toml or args.module or args.libs or args.no_venv or args.python != sys.executable:
            warn("Python-specific options are ignored for C/C++ projects.")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = build_parser()
    args: argparse.Namespace = parser.parse_args()
    validate_args(args, parser)

    lang = args.lang.lower()
    project_path: Path = Path(args.name)
    original_cwd: Path = Path.cwd()

    if project_path.exists():
        error(f"Directory '{args.name}' already exists.")
        sys.exit(1)

    print(f"{Ansi.BOLD}🌱 Sprouting '{args.name}' ({lang})...{Ansi.RESET}")

    try:
        project_path.mkdir(parents=True)
        os.chdir(project_path)

        if lang == "python":
            scaffold_python(args)
        else:
            scaffold_cpp_c(args, is_cpp=(lang in ("cpp", "c++")))

        if args.readme:
            generate_readme(args)

        if args.git:
            setup_git(lang, args.branch)

    except ScaffoldError as e:
        error(str(e))
        os.chdir(original_cwd)
        shutil.rmtree(project_path, ignore_errors=True)
        error("Rolled back partially created project.")
        sys.exit(1)
    except Exception as e:  # noqa: BLE001 - final safety net for unexpected errors
        error(f"Unexpected error: {e}")
        os.chdir(original_cwd)
        shutil.rmtree(project_path, ignore_errors=True)
        error("Rolled back partially created project.")
        sys.exit(1)

    success(f"Project '{args.name}' is ready!")


def setup_git(lang: str, branch: str) -> None:
    """
    Sets up a git repository by running git init and creating a basic
    .gitignore for the language.

    Args:
        lang (str): The language the project is written in.
        branch (str): The name to give the initial branch.
    """
    info("Initializing Git repository...")
    run(["git", "init", "-q", "-b", branch])
    template: str = GITIGNORE_TEMPLATES.get(lang, "# Basic gitignore\n.DS_Store\n")

    with open(".gitignore", "w") as f:
        f.write(template)
    success("Created .gitignore")


def generate_readme(args: argparse.Namespace) -> None:
    """Writes a minimal README.md so the project isn't checked in empty-handed."""
    info("Generating README.md...")
    with open("README.md", "w") as f:
        f.write(f"# {args.name}\n\nScaffolded with 🌱 sprout.py ({args.lang}).\n")
    success("Created README.md")


def scaffold_python(args: argparse.Namespace) -> None:
    """
    Scaffolds a Python project.

    Args:
        args (argparse.Namespace): The parsed CLI arguments.
    """
    pip_path: str = "venv/bin/pip" if os.name != "nt" else "venv\\Scripts\\pip"

    if not args.no_venv:
        info("Setting up Python venv...")
        run([args.python, "-m", "venv", "venv"])
    else:
        warn("Skipping venv creation (--no-venv).")

    if args.module:
        info("Setting up module structure...")
        pkg_name = args.name.replace("-", "_")
        src_path: Path = Path(pkg_name)
        src_path.mkdir(parents=True)
        (src_path / "__init__.py").touch()
        main_path: Path = src_path / "main.py"
    else:
        main_path = Path("main.py")

    with open(main_path, "w") as f:
        f.write('\nprint("Hello, Sprout!")\n')

    # Configuration Files
    if args.toml:
        info("Generating pyproject.toml...")
        with open("pyproject.toml", "w") as f:
            f.write(f'[project]\nname = "{args.name}"\nversion = "0.1.0"\n')

    # Install Libraries
    if args.libs:
        if args.no_venv:
            warn("Skipping library install: no venv was created (--no-venv).")
        else:
            info(f"Installing: {', '.join(args.libs)}...")
            try:
                run([pip_path, "install", *args.libs])
            except ScaffoldError as e:
                warn(f"Library install failed, continuing anyway: {e}")

    success("Python project scaffolded.")


def scaffold_cpp_c(args: argparse.Namespace, is_cpp: bool = False) -> None:
    """
    Scaffolds a C or C++ project with a src/include/build structure, and
    optionally a Makefile and/or CMakeLists.txt.

    Args:
        args (argparse.Namespace): The parsed CLI arguments.
        is_cpp (bool): True if the project is C++, else it is C.
    """
    ext = "cpp" if is_cpp else "c"
    compiler = "g++" if is_cpp else "gcc"
    lang_label = "C++" if is_cpp else "C"
    std = args.std or DEFAULT_STD["cpp" if is_cpp else "c"]

    info(f"Building {lang_label} project structure...")

    # Create directories
    for folder in ["src", "include", "build"]:
        Path(folder).mkdir(exist_ok=True)

    # Create entry point
    main_file = Path("src") / f"main.{ext}"
    with open(main_file, "w") as f:
        content = (
            "#include <iostream>\n\nint main() {\n    std::cout << \"Hello, Sprout!\" << std::endl;\n    return 0;\n}\n"
            if is_cpp else
            "#include <stdio.h>\n\nint main() {\n    printf(\"Hello, Sprout!\\n\");\n    return 0;\n}\n"
        )
        f.write(content)

    if args.make:
        info("Generating Makefile...")
        with open("Makefile", "w") as f:
            makefile = f"""CC = {compiler}
CFLAGS = -Iinclude -Wall -std={"c++" if is_cpp else "c"}{std}
SRC = $(wildcard src/*.{ext})
OBJ = $(SRC:src/%.{ext}=build/%.o)
TARGET = {args.name}

all: $(TARGET)

$(TARGET): $(OBJ)
\t$(CC) $(OBJ) -o $(TARGET)

build/%.o: src/%.{ext}
\tmkdir -p build
\t$(CC) $(CFLAGS) -c $< -o $@

clean:
\trm -rf build $(TARGET)
"""
            f.write(makefile)
        success("Created Makefile")

    if args.cmake:
        info("Generating CMakeLists.txt...")
        cmake_project_name = Path(args.name).name or "app"
        cmake_lang = "CXX" if is_cpp else "C"
        std_var = "CXX_STANDARD" if is_cpp else "C_STANDARD"
        with open("CMakeLists.txt", "w") as f:
            cmakelists = f"""cmake_minimum_required(VERSION {args.cmake_min})
project({cmake_project_name} LANGUAGES {cmake_lang})

set(CMAKE_{std_var} {std})
set(CMAKE_{std_var}_REQUIRED ON)
set(CMAKE_{std_var}_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

include_directories(include)

file(GLOB SOURCES "src/*.{ext}")

add_executable(${{PROJECT_NAME}} ${{SOURCES}})
"""
            f.write(cmakelists)
        success("Created CMakeLists.txt")

    if not args.make and not args.cmake:
        warn("No build system generated. Pass --make and/or --cmake to add one.")

    success(f"{lang_label} project scaffolded.")


if __name__ == "__main__":
    main()
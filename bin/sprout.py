#!/usr/bin/env python3

"""
sprout.py - A multi-language project scaffolding utility.

This script automates the creation of project structures for Python, C, and C++.
It handles directory creation, virtual environment setup, git initialization, 
and generates boilerplate files like Makefiles or pyproject.toml.
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path

GITIGNORE_TEMPLATES: dict[str, str] = {
    "python": "__pycache__/\n*.py[cod]\n*$py.class\nvenv/\n.env\n",
    "c": "*.o\n*.out\nbuild/\n",
    "cpp": "*.o\n*.out\n*.exe\nbuild/\n",
}

def main() -> None:
    """
    The Main Function.
    """
    parser = argparse.ArgumentParser(description="A Project Scaffolding Script")

    # General Arguments
    parser.add_argument("name", help="The name of the project directory to create.")
    parser.add_argument("-l", "--lang", default="python", help="The name of the programming language to scaffold.")
    parser.add_argument("-g", "--git", action="store_true", help="Initialize git and create .gitignore")

    # Python Arguments
    parser.add_argument("--toml", action="store_true", help="Generate a pyproject.toml")
    parser.add_argument("--module", action="store_true", help="Create a nested name/package directory structure")
    parser.add_argument("--libs", nargs="+", help="Space-separated list of libraries to install (e.g., requests flask)")

    # C/C++ Arguments
    parser.add_argument("--make", action="store_true", help="Generates a basic Makefile for the C/C++ project.")

    args: argparse.Namespace = parser.parse_args()

    project_path: Path = Path(args.name)

    # Check if directory exists
    if project_path.exists():
        print(f"Error: Directory '{args.name}' already exists.")
        sys.exit(1)
    print(f"🌱 Sprouting project in {project_path}...")
    project_path.mkdir(parents=True)
    os.chdir(project_path)

    match args.lang.lower():
        case "python": scaffold_python(args)
        case "c": scaffold_cpp_c(args, is_cpp=False)
        case "cpp": scaffold_cpp_c(args, is_cpp=True)
        case "c++": scaffold_cpp_c(args, is_cpp=True)

        case _:
            print(f"Language '{args.lang}' Not Supported by Sprout.")
            sys.exit(1)

    if args.git:
        setup_git(args.lang)

def setup_git(lang: str) -> None:
    """
    Setups a git repository be doing git init and creates a basic
    .gitignore for the language.

    Args:
        lang (str): The language the project is written in.
    """
    print("Initializing Git repository...")
    subprocess.run(["git", "init"], check=True)
    template: str = GITIGNORE_TEMPLATES.get(lang, "# Basic gitignore\n.DS_Store\n")

    with open(".gitignore", "w") as f:
        f.write(template)
    print("Created .gitignore")

def scaffold_python(args: argparse.Namespace) -> None:
    """
    Scaffolds a Python Project.

    Arsgs:
        args (argparse.Namespace): The arguments
    """
    print("🐍 Setting up Python venv...")
    subprocess.run(["python3", "-m", "venv", "venv"], check=True)

    pip_path: str = "venv/bin/pip" if os.name != "nt" else "venv\\Scripts\\pip"

    if args.module:
        print("📦 Setting up module structure (name/)...")
        src_path: Path = Path(args.name) / args.name.replace("-", "_")
        src_path.mkdir(parents=True)
        (src_path / "__init__.py").touch()
        main_path: Path = (src_path / "main.py")
        main_path.touch()
        
    else:
        main_path: Path = Path("main.py")
        main_path.touch()
        
    with open(main_path, 'w') as f:
        f.write("\nprint(\"Hello, Sprout!\")\n")

    # Configuration Files
    if args.toml:
        print("Generating pyproject.toml...")
        with open("pyproject.toml", "w") as f:
            f.write(f'[project]\nname = "{args.name}"\nversion = "0.1.0"\n')

    # Install Libraries
    if args.libs:
        print(f"Installing: {', '.join(args.libs)}...")
        subprocess.run([pip_path, "install", *args.libs])

    print("Done!")

def scaffold_cpp_c(args: argparse.Namespace, is_cpp: bool = False) -> None:
    """
    Scaffolds a C or C++ Project with src/include structure.

    Args:
        args (argparse.Namespace): The arguments.
        is_cpp (bool): True if project is C++ else it is C.
    """
    ext = "cpp" if is_cpp else "c"
    header_ext = "hpp" if is_cpp else "h"
    compiler = "g++" if is_cpp else "gcc"

    print(f"{"Building C++" if is_cpp else "Building C"} project structure...")

    # Create directories
    for folder in ["src", "include", "build"]:
        Path(folder).mkdir(exist_ok=True)

    # Create entry point
    main_file = Path("src") / f"main.{ext}"
    with open(main_file, "w") as f:
        content = (
            "#include <iostream>\n\nint main() {\n    std::cout << \"Hello, Sprout!\" << std::endl;\n    return 0;\n}"
            if is_cpp else
            "#include <stdio.h>\n\nint main() {\n    printf(\"Hello, Sprout!\\n\");\n    return 0;\n}"
        )
        f.write(content)

    if args.make:
        # Generate a basic Makefile
        print("Generating Makefile...")
        with open("Makefile", "w") as f:
            makefile = f"""CC = {compiler}
CFLAGS = -Iinclude -Wall
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
    
    print("Done!")

if __name__ == "__main__":
    main()
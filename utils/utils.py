"""Groups common functionality."""

from pathlib import Path

PROJECT_ROOT = Path.cwd()
"""This is where the project's root directory is."""


# Plugins

PROJECT_SRC = PROJECT_ROOT / "src"
"""This is where the project's src directory is."""

def find_plugin(arg: str) -> Path:
    p = PROJECT_SRC / arg
    return p.resolve(True)


# Site

PROJECT_SITE = PROJECT_ROOT / "site"
"""This is where the project's site directory is."""

PROJECT_SITE_LOCAL = PROJECT_ROOT / "site_local"
"""This is where the project's local site directory is."""

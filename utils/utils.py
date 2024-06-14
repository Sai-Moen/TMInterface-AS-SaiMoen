"""Groups common functionality."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).parents[1]
"""This is where the project's root directory is."""

PROJECT_SRC = PROJECT_ROOT / "src"
"""This is where the project's src directory is."""

def find_plugin(arg: str) -> Path:
    p = PROJECT_SRC / arg
    return p.resolve(True)

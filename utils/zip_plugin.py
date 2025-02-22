"""Zips the given plugin and puts that zip in lab/archive."""

from pathlib import PurePath
from sys import argv
from zipfile import ZipFile, ZIP_DEFLATED

from utils import PROJECT_ROOT, find_plugin

ARCHIVE = PROJECT_ROOT / "lab" / "archive"
"""This is where the zip will be placed."""

def main(args: list[str]):
    assert len(args) >= 1, "Plugin name is required!"

    p = find_plugin(args[0])
    out = ARCHIVE / p.stem
    with ZipFile(out.with_suffix(".zip"), 'w', ZIP_DEFLATED, compresslevel=9) as zf:
        name = p.name
        if p.is_file():
            zf.write(p, name)
            return

        for absolute, _, files in p.walk():
            relative = name / absolute.relative_to(p)
            for file in files:
                file = PurePath(file)
                if file.suffix == ".as":
                    zf.write(absolute / file, relative / file)

if __name__ == "__main__":
    main(argv[1:])

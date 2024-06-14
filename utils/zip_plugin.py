"""Zips the given plugin and puts that zip in lab/archive."""

from sys import argv
from zipfile import ZipFile, ZIP_DEFLATED

from utils import PROJECT_ROOT, find_plugin

def main_args(args: list[str] = argv):
    if len(args) < 2:
        print("You should provide a filename as an argument to this script.")
        return

    main(args[1])

ARCHIVE = PROJECT_ROOT / "lab" / "archive"
"""This is where the zip will be placed."""

def main(arg: str):
    p = find_plugin(arg)
    out = ARCHIVE / p.stem
    name = p.name
    with ZipFile(out.with_suffix(".zip"), 'w', ZIP_DEFLATED, compresslevel=9) as zf:
        if p.is_file():
            zf.write(p, name)
            return

        for root, _, files in p.walk():
            relative = name / root.relative_to(p)
            for file in files:
                absolute = root / file
                if file.casefold() == "readme.md":
                    zf.write(absolute, file)
                else:
                    zf.write(absolute, relative / file)

if __name__ == "__main__":
    main_args()

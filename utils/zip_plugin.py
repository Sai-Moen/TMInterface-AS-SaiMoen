"""Zips the file in argv[1] and puts that zip in lab/archive"""

from pathlib import Path
from sys import argv
from zipfile import ZipFile, ZIP_DEFLATED

def main():
    if len(argv) < 2:
        print("You should provide a filename as an argument to this script.")
        return

    cwd = Path.cwd()
    assert cwd.stem == "utils", "safety check"

    p = Path(argv[1])
    plugin_name = p.stem

    root = cwd.parent
    base_name = root / "lab" / "archive" / plugin_name
    root_dir = root / p
    assert root_dir.is_dir(), "argv[1] is not a valid Path"

    with ZipFile(base_name.with_suffix(".zip"), 'w', ZIP_DEFLATED, compresslevel=9) as zf:
        for dirpath, _, filenames in root_dir.walk():
            relative = plugin_name / dirpath.relative_to(root_dir)
            for f in filenames:
                zf.write(dirpath / f, relative / f)

if __name__ == "__main__":
    main()

"""Initializes the local site directory. Requires Ruby and Bundle to be installed."""

import subprocess as sp

from utils import PROJECT_SITE_LOCAL

def main():
    while PROJECT_SITE_LOCAL.exists():
        s = input(f"{PROJECT_SITE_LOCAL} exists already, delete? (y/n)\n")
        match s.casefold():
            case "n":
                print("Not deleting, exiting...")
                return
            case "y":
                print("Deleting...")
                delete_site_local()
                break
    PROJECT_SITE_LOCAL.mkdir()

    run(["bundle", "init"])
    run(["bundle", "add", "github-pages"])
    run(["bundle", "add", "webrick"])

def run(cmd: list[str]):
    sp.check_output(cmd, shell=True, cwd=PROJECT_SITE_LOCAL)

def delete_site_local():
    for root, dirs, files in PROJECT_SITE_LOCAL.walk(top_down=False):
        for f in files:
            (root / f).unlink()
        for d in dirs:
            (root / d).rmdir()
    root.rmdir()

if __name__ == "__main__":
    main()

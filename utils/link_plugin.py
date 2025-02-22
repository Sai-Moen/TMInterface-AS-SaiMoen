"""Links the given plugin into the Plugins directory."""

from sys import argv

from utils import PROJECT_ROOT, find_plugin

PLUGINS = PROJECT_ROOT.parent / "Plugins"
"""This is where TMInterface's Plugins directory is."""

def main(args: list[str]):
    assert len(args) >= 2, "Command and plugin name are required!"

    cmd = args[0].casefold()
    p = find_plugin(args[1])
    link = PLUGINS / p.name
    match cmd:
        case "link":
            link.symlink_to(p)
            print(f"{link} linked successfully to {p}")
        case "unlink":
            if link.is_symlink():
                link.unlink()
                print(f"{link} unlinked successfully")
            else:
                print("Cannot find symlink for this plugin...")
        case _:
            if cmd != "help":
                print("Unknown command!")
            print("Commands (given plugin means the path to a plugin in the second argument):")
            print("link - creates a symlink inside the Plugins directory to the given plugin.")
            print("unlink - removes the symlink to the given plugin that is inside the Plugins directory.")

if __name__ == "__main__":
    main(argv[1:])

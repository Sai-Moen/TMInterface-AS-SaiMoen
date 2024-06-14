"""Links the given plugin into the Plugins directory."""

from sys import argv

from utils import PROJECT_ROOT, find_plugin

def main_args(args: list[str] = argv):
    if len(args) < 3:
        print("You should provide a command and filename as arguments to this script.")
        return

    main(args[1], args[2])

PLUGINS = PROJECT_ROOT.parent / "Plugins"
"""This is where TMInterface's Plugins directory is."""

def main(cmd: str, arg: str):
    p = find_plugin(arg)
    link = PLUGINS / p.name
    match cmd.casefold():
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
            print("Unknown command!")
            print_commands()

def print_commands():
    print("Commands (given plugin means the path to a plugin in the second argument):")
    print("link - creates a symlink inside the Plugins directory to the given plugin.")
    print("unlink - removes the symlink to the given plugin that is inside the Plugins directory.")

if __name__ == "__main__":
    main_args()

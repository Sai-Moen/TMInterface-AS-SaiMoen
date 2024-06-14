// Command-Line Interface

void OnCommand(
    int fromTime,
    int toTime,
    const string &in commandLine,
    const array<string> &in args)
{
}

// Leave at the bottom because it makes the code unreadable
const string Help()
{
    return
"""
Commands:

    svcs toggle
Toggle the Graphical User Interface. (NOT YET IMPLEMENTED)

    svcs list
List all the created trees.

    svcs create [path]
Create a tree for the given path.
No operation if it is already tracked.

    svcs select [path] (branch) (commit)
Try to select a certain path, branch and commit to work from.
If branch is not given, it will select main.
If commit is not given, it will select leaf.

    svcs remove [path]
Try to remove the tree for a given path.
This untracks the script.

-- A script should be selected for the following commands (or an error could occur) --

    svcs deselect
Deselect current script.

    svcs cleanup (index/tag)
Tries to cleanup the tree until index (can be tag) is the oldest commit.
If index is not given it will cleanup until the newest commit that at least 1 branch is referencing.
WARNING: This will most likely remove most commits, specify index if possible.

    svcs load
Load the currently selected script + branch + commit combination.

    svcs branch list
List the branches of the selected script.

    svcs branch create [name]
Create a branch with the given name, based on the selected branch and commit.
No operation if it already exists.

    svcs branch select (name) (commit)
Select the branch with the given name.
If name is not given, it will select main.
If commit is not given, it will select leaf.

    svcs branch remove [name]
Remove the branch with the given name.
No operation if name is main.

    svcs commit list
List the commits of the selected branch.

    svcs commit create
Commit the current file changes to the leaf of the selected branch.
No operation if nothing changed.

    svcs commit select [index/tag]
Select the commit with the given index or tag.
Index is the amount of backwards steps from leaf.

    svcs commit remove
Undo the last commit.

    svcs commit tag [name]
Give the selected commit a certain name.
""";
}

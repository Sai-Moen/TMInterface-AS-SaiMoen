# Script Version Control System
### By SaiMoen
A way to save your changes and create branches with automatic backups!

## Terminology

        script
    A TMInterface script.

        run
    A script, excluding setup.

        run setup
    A common pattern where preparation commands, like speedup from/to a certain time or loading/saving a savestate, are at the bottom of a script.
    This is used to reduce boring tasks like getting to a certain point in the run.
    There can also be run-specific aliases, anything that can be done in the console really.

        tracked (script)
    A script that svcs is tracking (is aware of).

        commit
    A change to the script's history.

        tree
    Tree that represents the history of a tracked script and its branches.

        branch
    A version of the script's history, based on a certain commit and subsequent changes.

        leaf
    The most up-to-date commit of a branch.

        main (branch)
    The primary branch, often used as a default.

## Commands

### Hints
    [ ] means required argument.
    ( ) means optional argument.
    filename is the entire relative path after Scripts/ to the script.
    filename needs to include file extension.

### Command-Line Interface
        svcs help
    Return a help message.

        svcs gui (NOT YET IMPLEMENTED)
    Toggle the Graphical User Interface.

        svcs list
    List all of the created trees, with some extra information.

        svcs create [filename]
    Create a tree for the given filename.
    No operation if it is already tracked.

        svcs select [filename] (branch) (commit)
    Try to select a certain filename, branch and commit to work from.
    If branch is not given, it will select main.
    If commit is not given, it will select leaf.

        svcs remove [filename]
    Try to remove the tree for a given filename.
    This untracks the script.

#### A script needs to be selected for the following commands
        svcs deselect
    Deselect current script.

        svcs load
    Load the currently selected script.

        svcs commit list
    List the commits of the selected branch.

        svcs commit create
    Commit the current file changes to the leaf of the selected branch.
    No operation if nothing changed.

        svcs commit select [index]
    Select the commit with the given index.
    Index is the amount of backwards steps from leaf.

        svcs commit remove
    Undo the last commit.

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

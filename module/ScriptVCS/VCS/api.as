namespace API
{
    const string EMPTY = "";

    enum Result
    {
        OK,
        FileNotFound,
    }

    void Toggle()
    {
        Interface::Toggle();
    }

    const array<Tree>@ List()
    {
        const array<string>@ const keys = VCS::trees.GetKeys();
        uint len = keys.Length;

        array<Tree> trees = array<Tree>(len);
        for (uint i = 0; i < len; i++)
        {
            trees[i] = cast<Tree>(VCS::trees[keys[i]]);
        }
        return trees;
    }

    Result Create(const string &in path)
    {
        if (VCS::TreeExists(path) || VCS::TryAddTree(path))
        {
            return Result::OK;
        }
        else
        {
            return Result::FileNotFound;
        }
    }

    Result Select(
        const string &in path,
        const string &in branch = EMPTY,
        const string &in commit = EMPTY)
    {
        // TODO: have a tree pointer in VCS
    }

    // Leave at the bottom
    const string Help()
    {
        return
        """Commands:

            svcs help
        Return a help message.

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

        -- A script needs to be selected for the following commands --

            svcs deselect
        Deselect current script.

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

            svcs commit select [index]
        Select the commit with the given index.
        Index is the amount of backwards steps from leaf.

            svcs commit remove
        Undo the last commit.

            svcs commit tag [name]
        Give the selected commit a certain name.
        """
    }
}

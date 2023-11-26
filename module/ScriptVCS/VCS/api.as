namespace SVCS
{
    const string Ignore()
    {
        return string();
    }

    enum Result
    {
        Err, // Error on the VCS side

        OK, // Success

        // The rest are errors on the user side

        FileNotFound,
        TreeNotFound,
        BranchNotFound,
        CommitNotFound,
        IndexNotFound,

        NotSelected,
        BadIndex,
    }

    Result Toggle()
    {
        Interface::Toggle();
        return Result::OK;
    }

    Result List(array<Tree>@ &out trees)
    {
        trees = VCS::GetTrees();
        return Result::OK;
    }

    Result Create(const string &in path)
    {
        Result result;

        if (VCS::TreeExists(path))
        {
            result = Result::OK;
        }
        else if (VCS::CreateTree(path) && VCS::TryAddTree(path))
        {
            result = Result::OK;
        }
        else
        {
            result = Result::FileNotFound;
        }

        return result;
    }

    Result Select(
        const string &in path,
        const string &in branch,
        const string &in commit)
    {
        Result result;

        if (VCS::SelectTree(path))
        {
            result = BranchSelect(branch, commit);
        }
        else
        {
            result = Result::TreeNotFound;
        }

        return result;
    }

    Result Remove(const string &in path)
    {
        Result result;

        if (VCS::RemoveTree(path))
        {
            result = Result::OK;
        }
        else
        {
            result = Result::FileNotFound;
        }

        return result;
    }

    // A script should be selected for the following commands (or an error could occur)

    Result Deselect()
    {
        Result result;

        if (VCS::IsSelecting())
        {
            result = Result::OK;
        }
        else
        {
            result = Result::NotSelected;
        }
        VCS::Deselect();

        return result;
    }

    Result CleanupIndex(const Index index)
    {
        Result result;

        if (VCS::Cleanup(index))
        {
            result = Result::OK;
        }
        else
        {
            result = Result::IndexNotFound;
        }

        return result;
    }

    Result CleanupString(const string &in strIndex)
    {
        Result result;

        Index index;
        if (strIndex.IsEmpty())
        {
            result = VCS::Cleanup() ? Result::OK : Result::NotSelected;
        }
        else if (VCS::ParseStringDex(strIndex, index))
        {
            result = CleanupIndex(index);
        }
        else
        {
            result = Result::BadIndex;
        }

        return result;
    }

    Result Load()
    {
        Result result;

        if (VCS::LoadSelected())
        {
            result = Result::OK;
        }
        else
        {
            result = Result::NotSelected; // maybe check if valid
        }

        return result;
    }

    Result BranchSelect(
        const string &in branch,
        const string &in commit)
    {
        Result result;

        if (branch.IsEmpty() || VCS::SelectBranch(branch))
        {
            result = CommitSelect(commit);
        }
        else
        {
            result = Result::BranchNotFound;
        }

        return result;
    }

    Result CommitSelect(const string &in commit)
    {
        Result result;

        if (commit.IsEmpty() || VCS::SelectCommit(commit))
        {
            result = Result::OK;
        }
        else
        {
            result = Result::CommitNotFound;
        }

        return result;
    }

    // Leave at the bottom because it makes the code unreadable
    const string Help()
    {
        return
"""
Commands:

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
}

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
}

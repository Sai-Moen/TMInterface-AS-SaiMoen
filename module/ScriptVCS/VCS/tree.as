namespace Tree
{
    const string MAIN_BRANCH = "main";
}

class Tree
{
    Tree(CommandList@ _script)
    {
        @script = _script;
        valid = branches.Exists(Tree::MAIN_BRANCH);
    }

    CommandList@ script;
    dictionary branches;

    bool valid = false;
    bool Valid { get { return valid; } }

    Branch@ Main { get { return GetBranchUnsafe(Tree::MAIN_BRANCH); } }

    Branch@ GetBranchUnsafe(const string &in name) const
    {
        return cast<Branch>(branches[name]);
    }

    bool GetBranch(const string &in name, out Branch@ branch) const
    {
        return branches.Get(name, @branch);
    }

    Index HighestStart() const
    {
        const auto@ const arr = Dictionary::ForEachArr(
            branches,
            function(d, key)
            {
                return cast<Branch@>(d[key]).Start;
            });

        Index highest = Index::MIN;
        for (uint i = 0; i < arr.Length; i++)
        {
            const Index index = Index(arr[i]);
            if (index > highest)
            {
                highest = index;
            }
        }
        return highest;
    }

    array<InputCommand>@ Reconstruct() const
    {
    }
}

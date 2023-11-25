namespace VCS
{
    void Main()
    {
        LoadTrees();
    }

    Tree@ selectedTree;
    Branch@ selectedBranch;
    Commit@ selectedCommit;

    dictionary trees;

    array<Tree>@ GetTrees()
    {
        const array<string>@ const keys = trees.GetKeys();
        const uint len = keys.Length;

        trees = array<Tree>(len);
        for (uint i = 0; i < len; i++)
        {
            trees[i] = cast<Tree>(trees[keys[i]]);
        }
        return trees;
    }

    bool TreeExists(const string &in path)
    {
        return trees.Exists(path);
    }

    void LoadTrees()
    {
        const array<string>@ const paths = Structure::GetPaths();
        for (uint i = 0; i < paths.Length; i++)
        {
            TryAddTree(paths[i]);
        }
    }

    bool TryAddTree(const string &in path)
    {
        try
        {
            trees[path] = Tree(Structure::GetTree(path));
            return true;
        }
        catch
        {
            return false;
        }
    }

    bool SelectTree(const string &in name)
    {
        Tree@ tree;
        if (trees.Get(name, tree))
        {
            @selectedTree = tree;
            @selectedBranch = selectedTree.Main;
            @selectedCommit = selectedBranch.Leaf;
            return true;
        }
        return false;
    }

    bool RemoveTree(const string &in name)
    {
        return trees.Delete(name);
    }

    bool IsSelecting()
    {
        return
            selectedTree !is null &&
            selectedBranch !is null &&
            selectedCommit !is null;
    }

    void Deselect()
    {
        @selectedCommit = null;
        @selectedBranch = null;
        @selectedTree = null;
    }

    bool ParseStringDex(const string &in strIndex, Index &out index)
    {
        if (Index::Parse(strIndex, index))
        {
            return true;
        }
        else if (IsSelecting() && selectedBranch.TryGetTag(strIndex, index))
        {
            return selectedBranch.IndexExists(index);
        }
        else
        {
            index = Index::MAX;
            return false;
        }
    }

    void AutoCleanup()
    {
        // TODO
    }

    bool TryCleanup(const Index index)
    {
        return true; // TODO
    }

    bool SelectBranch(const string &in name)
    {
        Branch@ branch;
        if (selectedTree.GetBranch(name, branch))
        {
            @selectedBranch = branch;
            @selectedCommit = selectedBranch.Leaf;
            return true;
        }
        return false;
    }

    bool SelectCommit(const string &in name)
    {
        Commit@ commit;
        if (selectedBranch.GetCommit(name, commit))
        {
            @selectedCommit = commit;
            return true;
        }
        return false;
    }
}

typedef uint64 Index;

namespace Index
{
    Index MAX = ~Index(0);

    bool Parse(const string &in strIndex, Index &out index)
    {
        uint byteCount;
        index = Text::ParseUInt(strIndex, 10, byteCount);
        return byteCount > 0;
    }
}

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

    void LoadTrees()
    {
        const array<string>@ const paths = Structure::GetPaths();
        for (uint i = 0; i < paths.Length; i++)
        {
            TryAddTree(paths[i]);
        }
    }

    bool TreeExists(const string &in path)
    {
        return trees.Exists(path);
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
        return selectedTree is null;
    }

    void Deselect()
    {
        @selectedCommit = null;
        @selectedBranch = null;
        @selectedTree = null;
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

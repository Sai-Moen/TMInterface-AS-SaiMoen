namespace VCS
{
    void Main()
    {
        LoadTrees();
    }

    dictionary trees;

    Tree@ selectedTree;
    Branch@ selectedBranch;
    Commit@ selectedCommit;

    void LoadTrees()
    {
        const array<string>@ const paths = Structure::GetPaths();
        for (uint i = 0; i < paths.Length; i++)
        {
            TryAddTree(paths[i]);
        }
    }

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

    bool CreateTree(const string &in path)
    {
        return Structure::CreateTree(path);
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
        const bool treeExists = trees.Get(name, tree);
        if (treeExists)
        {
            @selectedTree = tree;
            @selectedBranch = selectedTree.Main;
            @selectedCommit = selectedBranch.Leaf;
        }
        return treeExists;
    }

    bool RemoveTree(const string &in name)
    {
        return trees.Delete(name) && Structure::SetPaths();
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

    bool Cleanup(const Index limit = Index::MIN)
    {
        const bool selecting = IsSelecting();
        if (selecting)
        {
            const Index highest = selectedTree.HighestStart();
            selectedBranch.Cleanup(limit > highest ? limit : highest);
        }
        return selecting;
    }

    bool LoadSelected()
    {
        const bool selecting = IsSelecting();
        if (selecting)
        {
            // TODO
        }
        return selecting;
    }

    bool SelectBranch(const string &in name)
    {
        Branch@ branch;
        const bool branchExists = selectedTree.GetBranch(name, @branch);
        if (branchExists)
        {
            @selectedBranch = branch;
            @selectedCommit = selectedBranch.Leaf;
        }
        return branchExists;
    }

    bool SelectCommit(const string &in strIndex)
    {
        Index index;
        Commit@ commit;
        const bool commitExists = ParseStringDex(strIndex, index) && selectedBranch.GetCommit(index, @commit);
        if (commitExists)
        {
            @selectedCommit = commit;
        }
        return commitExists;
    }
}

const string EMPTY = string();

typedef uint64 Index;

namespace Index
{
    const Index MIN = Index(0);
    const Index MAX = ~Index(0);

    bool Parse(const string &in strIndex, Index &out index)
    {
        uint byteCount;
        index = Text::ParseUInt(strIndex, 10, byteCount);
        return byteCount > 0;
    }
}

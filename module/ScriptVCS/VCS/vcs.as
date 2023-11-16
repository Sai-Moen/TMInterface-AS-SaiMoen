namespace Structure
{
    const string DIR = "svcs/";
    const string BASE = DIR + "tree_";
    const string META = DIR + "tree";
    const string META_SEP = "\0";

    const array<string>@ const GetPaths()
    {
        try
        {
            const CommandList cmdlist = CommandList(META);
            return cmdlist.Content.Split(META_SEP);
        }
        catch
        {
            return array<string>();
        }
    }
}

namespace VCS
{
    void Main()
    {
        LoadTrees();
    }

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
            trees[path] = Tree(CommandList(path));
            return true;
        }
        catch
        {
            return false;
        }
    }
}

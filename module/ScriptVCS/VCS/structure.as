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
            CommandList meta = CommandList(META);
            return meta.Content.Split(META_SEP);
        }
        catch
        {
            return array<string>();
        }
    }

    bool SetPaths()
    {
        try
        {
            CommandList meta = CommandList(META);
            meta.Content = Text::Join(VCS::trees.GetKeys(), META_SEP);
            meta.Save(META);
            return true;
        }
        catch
        {
            return false;
        }
    }

    bool CreateTree(const string &in path)
    {
        CommandList newTree = CommandList();
        return newTree.Save(BASE + path);
    }

    CommandList GetTree(const string &in path)
    {
        return CommandList(BASE + path);
    }
}

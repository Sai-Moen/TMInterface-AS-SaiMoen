namespace Structure
{
    const string EMPTY = "";
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
        // TODO: Add main branch with 1 commit (the original file)
        return newTree.Save(BASE + path);
    }

    CommandList GetTree(const string &in path)
    {
        return CommandList(BASE + path);
    }

    string Key(const string &in source, const uint start, out uint new)
    {
        const int EXCESS = 2;
        const uint8 DELIMITER = ReservedBytes['\"'];
        const uint8 SEP = ReservedBytes[':'];

        bool inContext = false;
        bool isKeyed = false;
        uint old;
        for (uint i = start; i < source.Length; i++)
        {
            const uint8 s = source[i];
            if (s == DELIMITER)
            {
                if (inContext)
                {
                    isKeyed = true;
                }
                else
                {
                    inContext = true;
                    old = i + 1;
                }
            }
            else if (isKeyed && s == SEP)
            {
                new = i + 1;
                return source.Substr(old, new - old - EXCESS);
            }
        }

        new = source.Length;
        return EMPTY;
    }
}

const dictionary ReservedBytes =
{
    {'', ""},
    {'\"', "\""[0]},
    {':', ":"[0]}, // also 0x3a
    
    {'{', "{"[0]},
    {'}', "}"[0]},
    {'[', "["[0]},
    {']', "]"[0]},
    {',', ","[0]},

    // Avoid detecting these as digits
    {';', ";"[0]}, // 0x3b
    {'<', "<"[0]}, // 0x3c
    {'=', "="[0]}, // 0x3d
    {'>', ">"[0]}, // 0x3e
    {'?', "?"[0]}  // 0x3f
};

bool IsDigit(string c)
{
    // 0x30 is latin1 digits and some symbols
    // 0xb0 also checks if UTF-8 bit is set
    return c[0] & 0xb0 == 0x30;
}

namespace Tree
{
    const string EMPTY = "";
    const string MAIN_BRANCH = "main";

    dictionary Parse(const string &in tree)
    {
        dictionary branches;

        uint i;
        while (i < tree.Length)
        {
            string key = Key(tree, i, i);
            string value = Value(tree, i, i);

            if (key == EMPTY || value == EMPTY)
            {
                continue;
            }

            branches[key] = value;
        }

        return branches;
    }

    string Key(const string &in tree, const uint start, out uint new)
    {
        const int EXCESS = 1;
        const uint8 DELIMITER = '"'[0];

        bool inContext = false;
        uint old;
        for (uint i = start; i < tree.Length; i++)
        {
            const uint8 s = tree[i];
            if (s == DELIMITER)
            {
                if (inContext)
                {
                    new = i + 1;
                    return tree.Substr(old, new - old - EXCESS);
                }
                else
                {
                    inContext = true;
                    old = i + 1;
                }
            }
        }

        new = tree.Length;
        return EMPTY;
    }

    string Value(const string &in tree, const uint start, out uint new)
    {
        const int EXCESS = 2;
        const uint8 OPEN = '{'[0];
        const uint8 CLOSE = '}'[0];
        const uint8 SEP = ','[0];

        const int NO_DEPTH = -1;
        int depth = NO_DEPTH;

        uint old;
        for (uint i = start; i < tree.Length; i++)
        {
            const uint8 s = tree[i];
            if (s == OPEN)
            {
                if (depth == NO_DEPTH)
                {
                    depth = 1;
                    old = i + 1;
                }
                else
                {
                    depth++;
                }
            }
            else if (s == CLOSE)
            {
                depth--;
            }
            else if (s == SEP && depth == 0)
            {
                new = i + 1;
                return tree.Substr(old, new - old - EXCESS);
            }
        }

        new = tree.Length;
        return EMPTY;
    }
}

class Tree
{
    Tree(CommandList@ _script)
    {
        @script = _script;
        dictionary parsed = Tree::Parse(script.Content);
        if (parsed is null)
        {
            return;
        }

        const array<string>@ const keys = parsed.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            branches[key] = Branch(parsed[key]);
        }

        success = true;
    }

    CommandList@ script;
    dictionary branches;

    bool success = false;
    bool Success { get { return success; } }

    Branch@ Main { get { return GetBranchUnsafe(Tree::MAIN_BRANCH); } }

    bool GetBranch(const string &in name, out Branch branch)
    {
        return branches.Get(name, branch);
    }

    Branch@ GetBranchUnsafe(const string &in name)
    {
        return cast<Branch>(branches[name]);
    }
}

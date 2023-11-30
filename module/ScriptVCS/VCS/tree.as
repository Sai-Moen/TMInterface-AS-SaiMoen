namespace Tree
{
    const string MAIN_BRANCH = "main";

    dictionary Deserialize(const string &in tree)
    {
        dictionary branches;

        uint i = 0;
        while (i < tree.Length)
        {
            string key = Key(tree, i, i);
            string value = Value(tree, i, i);

            if (key.IsEmpty() || value.IsEmpty())
            {
                continue;
            }

            branches[key] = value;
        }

        return branches;
    }

    string Key(const string &in tree, const uint start, out uint new)
    {
        return Structure::Key(tree, start, new);
    }

    string Value(const string &in tree, const uint start, out uint new)
    {
        const int EXCESS = 2;
        const uint8 OPEN = ReservedBytes['{'];
        const uint8 CLOSE = ReservedBytes['}'];
        const uint8 SEP = ReservedBytes[','];

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
        dictionary parsed = Tree::Deserialize(script.Content);

        dictionary branchesChildren;

        const array<string>@ const keys = parsed.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];

            const array<string>@ childNames;
            Branch@ const branch = Branch(parsed[key], @childNames);
            branches[key] = branch;

            if (branch.Valid)
            {
                branchesChildren[key] = childNames;
            }
        }

        const array<string>@ const childKeys = branchesChildren.GetKeys();
        for (uint i = 0; i < childKeys.Length; i++)
        {
            const string key = childKeys[i];
            Branch@ const branch = branches[key];

            const array<string>@ const childNames = branchesChildren[key];
            for (uint j = 0; j < childNames.Length; j++)
            {
                branch.AddChild(branches[childNames[j]]);
            }
        }

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

    bool GetBranch(const string &in name, out Branch branch) const
    {
        return branches.Get(name, branch);
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
}

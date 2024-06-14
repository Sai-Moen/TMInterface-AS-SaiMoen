namespace Branch
{
    const int NAME_LEN = 0x40;
}

class Branch
{
    Branch(const Data@ const branch, array<string>@ &out childNames)
    {
        valid = true;
    }

    array<Commit> commits;
    dictionary tags;

    dictionary children;

    string name;
    string Name
    {
        get const { return name; }
        set { name = value.Substr(0, Branch::NAME_LEN); }
    }

    Index start;
    Index Start { get const { return start; } }

    bool valid = false;
    bool Valid { get const { return valid; } }

    Commit@ Leaf
    {
        get const
        {
            if (commits.IsEmpty())
            {
                return null;
            }

            return commits[0];
        }
    }

    bool IndexExists(const Index index) const
    {
        return index < commits.Length;
    }

    bool TryGetTag(const string &in tag, Index &out index) const
    {
        return tags.Get(tag, index);
    }

    bool GetCommit(const Index index, Commit@ &out commit) const
    {
        if (IndexExists(index))
        {
            @commit = commits[index];
            return true;
        }
        else
        {
            @commit = null;
            return false;
        }
    }

    void AddChild(const Branch@ const branch)
    {
        children.Add(branch);
    }

    void Cleanup(const Index index)
    {
        if (IndexExists(index))
        {
            commits.Resize(index + 1);
        }
    }
}

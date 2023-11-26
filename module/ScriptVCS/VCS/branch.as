namespace Branch
{
    const string KEY_COMMITS = "commits";
    const string KEY_TAGS = "tags";
    const string KEY_START = "start";
    const string KEY_CHILDREN = "children";
    const uint KEY_N = 4;

    dictionary Deserialize(const string &in branch)
    {
        dictionary parsed;

        uint j = 0;
        for (uint i = 0; i < KEY_N; i++)
        {
            const string key = Structure::Key(branch, j, j);
            const string value = Structure::Value(branch, j, j);

            parsed[key] = value;
        }

        return parsed;
    }

    array<Commit>@ DeserializeCommits(const string &in commits)
    {
        const array<string>@ const split = commits.Split(",");

        array<Commit>@ const parsed = array<Commit>(split.Length);
        for (uint i = 0; i < split.Length; i++)
        {
            parsed[i] = Commit(split[i]);
        }

        return parsed;
    }

    dictionary@ DeserializeTags(const string &in tags)
    {
        dictionary parsed;

        uint i = 0;
        while (i < tags.Length)
        {
            const string key = TagKey(tags, i, i);
            const Index tag = TagValue(tags, i, i);

            if (key.IsEmpty() || tag.IsEmpty())
            {
                continue;
            }

            parsed[key] = tag;
        }

        return parsed;
    }

    string TagKey(const string &in tag, const uint start, uint out& new)
    {
        return Structure::Key(tag, start, new);
    }

    Index TagValue(const string &in tag, const uint start, uint out& new)
    {
        bool isParsingNumber = false;
        uint old;
        for (uint i = start; i < tag.Length; i++)
        {
            const uint8 s = tag[i];
            if (IsDigit(s))
            {
                isParsingNumber = true;
                old = i;
            }
            else if (isParsingNumber)
            {
                new = i;

                Index index;
                bool ignore = Index::Parse(tag.Substr(old, new - old), index);
                return index;
            }
        }

        new = tag.Length;
        return Index::MAX;
    }

    Index DeserializeIndex(const string &in strIndex)
    {
        Index index;
        bool ignore = Index::Parse(strIndex, index);
        return index;
    }

    array<string>@ DeserializeChildren(const string &in children)
    {
        return children.Split(",");
    }
}

class Branch
{
    Branch(const string &in branch, array<string>@ &out childNames)
    {
        dictionary@ const fields = Branch::Deserialize(branch);

        string strCommits;
        if (!fields.Get(KEY_COMMITS, strCommits)) return;
        commits = Branch::DeserializeCommits(strCommits);

        string strTags;
        if (!fields.Get(KEY_TAGS, strTags)) return;
        tags = Branch::DeserializeTags(strTags);

        string strIndex;
        if (!fields.Get(KEY_INDEX, strIndex)) return;
        start = Branch::DeserializeIndex(strIndex);

        string strChildren;
        if (!fields.Get(KEY_CHILDREN, strChildren)) return;
        childNames = Branch::DeserializeChildren(strChildren);

        valid = true;
    }

    array<Commit> commits;
    dictionary tags;

    Index start;
    Index Start { get { return start; } }

    array<Branch@> children;

    bool valid = false;
    bool Valid { get { return valid; } }

    Commit@ Leaf
    {
        get
        {
            if (commits.IsEmpty())
            {
                return null;
            }

            return commits[0];
        }
    }

    bool TryGetTag(const string &in tag, Index &out index)
    {
        return tags.Get(tag, index);
    }

    bool IndexExists(const Index index)
    {
        return index < commits.Length;
    }

    void Cleanup(const Index index)
    {
        if (IndexExists(index))
        {
            commits.Resize(index + 1);
        }
    }

    bool GetCommit(const Index index, Commit@ &out commit)
    {
        if (IndexExists(index))
        {
            @commit = commits[index];
            return true;
        }
        else
        {
            return false;
        }
    }

    void AddChild(const Branch@ const branch)
    {
        children.Add(branch);
    }
}

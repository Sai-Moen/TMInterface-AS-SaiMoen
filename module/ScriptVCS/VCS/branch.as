namespace Branch
{
    // Add a space to avoid random serialized data from splitting
    const string SEP = ", ";

    const string KEY_COMMITS = "commits";
    const string KEY_TAGS = "tags";

    dictionary Deserialize(const string &in branch)
    {
        dictionary parsed;

        uint j = 0;
        for (uint i = 0; i < 2; i++)
        {
            const string key = Structure::Key(branch, j, j);
            const string value = Structure::Value(branch, j, j);

            parsed[key] = value;
        }

        return parsed;
    }

    array<Commit>@ DeserializeCommits(const string &in commits)
    {
        const array<string>@ const split = commits.Split(SEP);

        array<Commit>@ const parsed = array<Commit>(split.Length);
        for (uint i = 0; i < split.Length; i++)
        {
            parsed[i] = Commit(split[i]);
        }

        return parsed;
    }

    dictionary DeserializeTags(const string &in tags)
    {
        dictionary parsed;

        uint i = 0;
        while (i < tags.Length)
        {
            const string key = TagKey(tags, i, i);
            const Index tag = TagValue(tags, i, i);

            if (key == EMPTY || tag == EMPTY)
            {
                continue;
            }

            parsed[key] = tag;
        }

        return parsed;
    }

    string TagKey(const string &in tag, const uint start, out uint new)
    {
        return Structure::Key(tag, start, new);
    }

    Index TagValue(const string &in tag, const uint start, out uint new)
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
                bool ignore = ParseIndex(tag.Substr(old, index));
                return index;
            }
        }

        new = tag.Length;
        return EMPTY;
    }
}

class Branch
{
    Branch(const string &in branch)
    {
        dictionary fields = Branch::Deserialize(branch);
        
        string strCommits;
        if (!fields.Get(KEY_COMMITS, strCommits)) return;
        commits = Branch::DeserializeCommits(strCommits);

        string strTags;
        if (!fields.Get(KEY_TAGS, strTags)) return;
        tags = Branch::DeserializeTags(strTags);

        valid = true;
    }

    array<Commit> commits;
    dictionary tags;

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
}

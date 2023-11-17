namespace Branch
{
    const string KEY_COMMITS = "commits";
    const string KEY_TAGS = "tags";

    dictionary Parse(string branch)
    {
        // Parse into Branch fields
    }

    array<string>@ ParseCommits(string commits)
    {
        const string SEP = ",";
        return commits.Split(SEP);
    }

    dictionary ParseTags(string commits)
    {
        dictionary tags;

        uint i = 0;
        while (i < commits.Length)
        {
            const string key = Key(commits, i, i);
            const string tag = Tag(commits, i, i);

            if (key == EMPTY || tag == EMPTY)
            {
                continue;
            }

            tags[key] = tag;
        }

        return tags;
    }

    string Key(const string &in tag, const uint start, out uint new)
    {
        return Structure::Key(tag, start, new);
    }

    string Tag(const string &in tag, const uint start, out uint new)
    {
        for (uint i = start; i < tag.Length; i++)
        {
            const string s = tag[i];
            // Detect number
        }

        new = tag.Length;
        return EMPTY;
    }
}

class Branch
{
    Branch(string branch)
    {
        dictionary fields = Branch::Parse(branch);
        // Parse specific fields
    }

    array<Commit> commits;
    dictionary tags;

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

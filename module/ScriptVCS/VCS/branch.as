class Branch
{
    Branch(string branch)
    {
        // Parse branch
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

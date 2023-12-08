namespace Commit
{
}

class Commit
{
    Commit() {} // For array<Commit>

    Commit(const ?@ commit)
    {
        valid = true;
    }

    ? data;

    bool valid = false;
    bool Valid { get { return valid; } }
}

namespace Commit
{
    // 'Static' methods
}

class Commit
{
    Commit(const Data@ const commit)
    {
        @data = commit;
        valid = data !is null;
    }

    Data@ data;

    bool valid = false;
    bool Valid { get { return valid; } }
}

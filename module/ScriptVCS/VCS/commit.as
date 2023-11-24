namespace Commit
{
    enum Mode
    {
        Null,

        Diff = 1 << 0,
        Base = 1 << 1,
    }
    const uint MODE_SIZE = 1;

    enum Op
    {
        Null,

        // Width of InputType
        Com = 1 << 4, // Compressed
        Add = 1 << 5,
        Del = 1 << 6,
    }

    bool TestFlag(uint8 n, Op flag)
    {
        return n & flag == flag;
    }

    bool TestFlag(uint8 n, Op flag, Op cmp)
    {
        return n & flag == cmp;
    }

    const string KEY_BASE = "base";
    const string KEY_DATA = "data";

    dictionary Deserialize(const string &in commit, bool &out valid)
    {
        dictionary parsed;

        string decoded;
        if (!commit.IsEmpty() && Decode::b64(commit, decoded))
        {
            switch (decoded[0])
            {
            case Mode::Diff:
                parsed[KEY_BASE] = false;
                parsed[KEY_DATA] = decoded;
                valid = true;
                break;
            case Mode::Base:
                parsed[KEY_BASE] = true;
                parsed[KEY_DATA] = decoded;
                valid = true;
                break;
            default:
                break;
            }
        }

        return parsed;
    }
}

class Commit
{
    Commit() {} // For array<Commit>

    Commit(const string &in commit)
    {
        dictionary fields = Commit::Deserialize(commit, valid);
        if (!valid) return;
        if (!fields.Get(KEY_BASE, base)) return;
        if (!fields.Get(KEY_DATA, data)) return;

        valid = true;
    }

    string data;
    array<InputCommand> Data
    {
        get
        {
            if (base)
            {
                return Decode::Base(data);
            }
            else
            {
                return Decode::Diff(data);
            }
        }
    }

    bool base = false;
    bool Base { get { return base; } }

    bool valid = false;
    bool Valid { get { return valid; } }
}

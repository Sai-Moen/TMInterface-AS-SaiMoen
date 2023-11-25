namespace Commit
{
    const string KEY_BASE = "base";
    const string KEY_DATA = "data";

    dictionary Deserialize(const string &in commit, bool &out valid)
    {
        dictionary parsed;

        string decoded;
        if (!commit.IsEmpty() && EnDec::Decode::b64(commit, decoded))
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

    bool base = false;
    bool Base { get { return base; } }

    bool valid = false;
    bool Valid { get { return valid; } }

    array<InputCommand> GetData(bool addOp = false)
    {
        if (base)
        {
            return EnDec::Decode::Base(data);
        }
        else if (addOp)
        {
            return EnDec::Decode::DiffAdd(data);
        }
        else
        {
            return EnDec::Decode::DiffDel(data);
        }
    }
}

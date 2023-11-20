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

        if (!commit.IsEmpty())
        {
            switch (commit[0])
            {
            case Mode::Diff:
                parsed[KEY_BASE] = false;
                parsed[KEY_DATA] = DecodeDiff(commit);
                valid = true; // Maybe check decoders
                break;
            case Mode::Base:
                parsed[KEY_BASE] = true;
                parsed[KEY_DATA] = DecodeBase(commit);
                valid = true; // Maybe check decoders
                break;
            default:
                break;
            }
        }

        return parsed;
    }

    array<InputCommand> DecodeDiff(const string &in encoded)
    {
        array<InputCommand> decoded;

        uint len = encoded.Length;
        uint offset = len;
        for (uint i = MODE_SIZE; i < len; i += offset)
        {
            // look at flags, decode diff
        }

        return decoded;
    }

    array<InputCommand> DecodeBase(const string &in encoded)
    {
        array<InputCommand> decoded;

        uint len = encoded.Length;
        uint offset = len;
        for (uint i = MODE_SIZE; i < len; i += offset)
        {
            if (TestFlag(encoded[i], Op::Com))
            {
                decoded.Add(DecodeBaseCompressed(encoded, i, offset));
            }
            else
            {
                decoded.Add(DecodeBaseRaw(encoded, i, offset));
            }
        }

        return decoded;
    }

    InputCommand DecodeBaseCompressed(const string &in encoded, uint start, uint &out offset)
    {
        offset = 2;

        InputCommand cmd;
        cmd.Type = encoded[start] & 0xf;
        cmd.Timestamp = Decompress(encoded, start, offset);
        cmd.State     = Decompress(encoded, start, offset);

        return offset;
    }

    InputCommand DecodeBaseRaw(const string &in encoded, uint start, uint &out offset)
    {
        return InputCommand(); // implement this
    }

    int Decompress(const string &in encoded, uint forward, uint& offset)
    {
        forward += offset;
        const uint8 rawBitsCount = 0x1f - encoded[forward - 1];
        const uint remainingBytes = (rawBitsCount >> 3) + 1;
        offset += remainingBytes + 1;

        int val;
        for (uint i = 0; i < remainingBytes; i++)
        {
            const uint shift = (remainingBytes - i) << 3;
            val &= encoded[forward + i] << shift;
        }
        return val;
    }
}

class Commit
{
    Commit() {} // For array<Commit>

    Commit(const string &in commit)
    {
        dictionary fields = Commit::Deserialize(commit, valid);
        if (!valid) return;

        // Probably needs some cast...
        if (!fields.Get(KEY_BASE, base)) return;
        if (!fields.Get(KEY_DATA, data)) return;

        valid = true;
    }

    array<InputCommand> data;

    bool base = false;
    bool Base { get { return base; } }

    bool valid = false;
    bool Valid { get { return valid; } }
}

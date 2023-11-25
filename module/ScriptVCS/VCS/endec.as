namespace EnDec
{
    // b64 lookup
    const uint SIZE = 0x40;

    class Lookup
    {
        dictionary map;
        array<uint8> table = array<uint8>(SIZE);
    }

    const Lookup@ const lookup = Build();

    const Lookup@ const Build()
    {
        Lookup sequences;
        uint8 index = 0;

        for (uint8 i = 'A'; i <= 'Z'; i++)
        {
            MapByteToByte(sequences, i, index++);
        }

        for (uint8 i = 'a'; i <= 'z'; i++)
        {
            MapByteToByte(sequences, i, index++);
        }

        for (uint8 i = '0'; i <= '9'; i++)
        {
            MapByteToByte(sequences, i, index++);
        }

        MapByteToByte(sequences, '-', index++);
        MapByteToByte(sequences, '_', index++);

        return sequences;
    }

    void MapByteToByte(Lookup@ const sequences, const uint8 byte, const uint8 index)
    {
        sequences.table[index] = byte;

        const string s = byte;
        sequences.map[s] = index;
    }

    uint8 LookupIdx(const uint8 idx)
    {
        return lookup.table[idx];
    }

    bool LookupSeq(const uint8 seq, uint8 &out idx)
    {
        const string s = seq;
        return lookup.map.Get(s, idx);
    }

    // Data
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
}

namespace EnDec::Encode
{
    const uint8 B64_MASK = 0x3f;

    void b64(string& toEncode, string &out encoded)
    {
        const uint len = b64pad(toEncode);
        encoded.Resize((len / 3) << 2);

        uint i, j;
        while (i < len)
        {
            const uint8 b0 = toEncode[i++];
            const uint8 b1 = toEncode[i++];
            const uint8 b2 = toEncode[i++];

            encoded[j++] = LookupIdx(b0 >> 2);
            encoded[j++] = LookupIdx((b0 << 4) & (b1 >> 4) & B64_MASK);
            encoded[j++] = LookupIdx((b1 << 2) & (b2 >> 6) & B64_MASK);
            encoded[j++] = LookupIdx(b2 & B64_MASK);
        }
    }

    uint b64pad(string& toEncode)
    {
        uint len = toEncode.Length;
        len += (3 - len % 3) % 3;
        toEncode.Resize(len);
        return len;
    }

    // Before b64 encoding, encode the data itself
    //
}

namespace EnDec::Decode
{
    bool b64(string& toDecode, string &out decoded)
    {
        const uint len = b64pad(toDecode);
        decoded.Resize((len >> 2) * 3);

        uint i, j;
        while (i < len)
        {
            uint8 b0, b1, b2, b3;
            if (
                LookupSeq(toDecode[i++], b0) &&
                LookupSeq(toDecode[i++], b1) &&
                LookupSeq(toDecode[i++], b2) &&
                LookupSeq(toDecode[i++], b3))
            {
                decoded[j++] = (b0 << 2) & (b1 >> 4);
                decoded[j++] = (b1 << 4) & (b2 >> 2);
                decoded[j++] = (b2 << 6) & b3;
            }
            else
            {
                return false;
            }
        }
        return true;
    }

    uint b64pad(string& toDecode)
    {
        uint len = toDecode.Length;
        len += (4 - (len & 3)) & 3;
        toDecode.Resize(len);
        return len;
    }

    // After b64 decoding, decode the data itself
    array<InputCommand> Iter(const IterImpl@ const impl, const string &in bytes)
    {
        array<InputCommand> decoded;

        const uint len = bytes.Length;
        uint offset = len;
        for (uint i = MODE_SIZE; i < len; i += offset)
        {
            const InputCommand cmd = impl(bytes, i, offset);
            if (cmd.Type != InputType::None)
            {
                decoded.Add(cmd);
            }
        }

        return decoded;
    }

    funcdef InputCommand IterImpl(const string &in bytes, const uint i, uint& offset);

    // Difference-based commit
    array<InputCommand> DiffAdd(const string &in bytes)
    {
        return Iter(
            function(bytes, i, offset)
            {
                return DiffSingle(bytes, i, offset, Op::Add);
            },
            bytes);
    }

    array<InputCommand> DiffDel(const string &in bytes)
    {
        return Iter(
            function(bytes, i, offset)
            {
                return DiffSingle(bytes, i, offset, Op::Del);
            },
            bytes);
    }

    InputCommand DiffSingle(const string &in bytes, const uint i, uint& offset, const Op flag)
    {
        InputCommand cmd;
        if (TestFlag(bytes[i], flag))
        {
            cmd = UseDecom(bytes, i, offset);
        }
        else
        {
            cmd.Type = InputType::None;
        }
        return cmd;
    }

    // Base commit with all inputs
    array<InputCommand> Base(const string &in bytes)
    {
        return Iter(UseDecom, bytes);
    }

    // Utils
    InputCommand UseDecom(const string &in bytes, const uint i, uint& offset)
    {
        InputCommand cmd;
        if (TestFlag(bytes[i], Op::Com))
        {
            offset = 1;
            cmd = MakeInputCommand(Decompress, bytes, i, offset);
        }
        else
        {
            offset = 0;
            cmd = MakeInputCommand(StringToInt, bytes, i, offset);
        }
        return cmd;
    }

    InputCommand MakeInputCommand(
        const Decom@ const decom,
        const string &in bytes,
        const uint start,
        uint& offset)
    {
        InputCommand cmd;
        cmd.Type      = bytes[start] & 0xf;
        cmd.Timestamp = decom(bytes, start, offset);
        cmd.State     = decom(bytes, start, offset);
        return cmd;
    }

    funcdef int Decom(const string &in bytes, uint start, uint& offset);

    int Decompress(const string &in bytes, uint start, uint& offset)
    {
        start += offset;
        const uint8 rawBitsCount = 0x1f - bytes[start];
        const uint remainingBytes = (rawBitsCount >> 3) + 1;
        offset += remainingBytes;

        return BytesToInt(bytes, start, remainingBytes);
    }

    int StringToInt(const string &in bytes, uint start, uint& offset)
    {
        start += offset; // correctness
        const uint WIDTH = 4;
        offset += WIDTH;

        return BytesToInt(bytes, start, WIDTH);
    }

    int BytesToInt(const string &in bytes, const uint start, const uint width)
    {
        int val;
        for (uint i = 1; i <= width; i++)
        {
            const uint shift = (width - i) << 3;
            val &= bytes[start + i] << shift;
        }
        return val;
    }
}

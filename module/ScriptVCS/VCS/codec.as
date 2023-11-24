// Encode/Decode

namespace Encode
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

            encoded[j++] = b0 >> 2;
            encoded[j++] = (b0 << 4) & (b1 >> 4) & B64_MASK;
            encoded[j++] = (b1 << 2) & (b2 >> 6) & B64_MASK;
            encoded[j++] = b2 & B64_MASK;
        }
    }

    uint b64pad(string& toEncode)
    {
        uint len = toEncode.Length;
        len += (3 - len % 3) % 3;
        toEncode.Resize(len);
        return len;
    }
}

namespace Decode
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
                sequenceTable.Get(toDecode[i++], b0) &&
                sequenceTable.Get(toDecode[i++], b1) &&
                sequenceTable.Get(toDecode[i++], b2) &&
                sequenceTable.Get(toDecode[i++], b3))
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

    array<InputCommand> Diff(const string &in bytes)
    {
        array<InputCommand> decoded;

        const uint len = bytes.Length;
        uint offset = len;
        for (uint i = MODE_SIZE; i < len; i += offset)
        {
            if (TestFlag(bytes[i], ::Commit::Op::Add))
            {
                //
            }
            else if (TestFlag(bytes[i], ::Commit::Op::Del))
            {
                //
            }
            else
            {
                //
            }
        }

        return decoded;
    }

    array<InputCommand> Base(const string &in bytes)
    {
        array<InputCommand> decoded;

        const uint len = bytes.Length;
        uint offset = len;
        for (uint i = MODE_SIZE; i < len; i += offset)
        {
            InputCommand cmd;
            if (TestFlag(bytes[i], ::Commit::Op::Com))
            {
                offset = 1;
                cmd = BaseCom(Decompress, bytes, i, offset);
            }
            else
            {
                offset = 0;
                cmd = BaseCom(StringToInt, bytes, i, offset);
            }
            decoded.Add(cmd);
        }

        return decoded;
    }

    InputCommand BaseCom(
        const Decom@ const decom,
        const string &in bytes,
        uint start,
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

    int BytesToInt(const string &in bytes, uint start, uint width)
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

const dictionary sequenceTable = BuildSequenceTable();

const dictionary BuildSequenceTable()
{
    dictionary sequences;
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

void MapByteToByte(dictionary& sequences, const uint8 byte, const uint8 index)
{
    const string s = byte;
    sequences[s] = index;
}

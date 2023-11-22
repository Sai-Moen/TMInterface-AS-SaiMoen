// Encode/Decode

namespace Encode
{
    bool b64(const string &in toEncode, string &out encoded)
    {
        //
        return true;
    }
}

namespace Decode
{
    bool b64(const string &in toDecode, string &out decoded)
    {
        const uint len = toDecode.Length;
        decoded.Resize(((len + 1) >> 2) * 3);

        const uint remainderBelow4 = len - 3;
        uint i, j;
        while (i < remainderBelow4)
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
                decoded[j++] = (b2 << 6) & (b3 >> 0);
            }
            else
            {
                return false;
            }
        }

        const uint remainder = len - i;
        array<uint8> remainingBytes = array<uint8>(4);
        while (i < len)
        {
            uint8 b0;
            if (sequenceTable.Get(toDecode[i], b0))
            {
                remainingBytes[(i++ + remainder) - len] = b0;
            }
            else
            {
                return false;
            }
        }

        for (uint k = 0; k < remainder; k++)
        {
            const uint8 b0 = remainingBytes[k];
            const uint8 b1 = remainingBytes[k + 1];
            decoded[j++] = (b0 << ((k + 1) << 1)) & (b1 >> ((2 - k) << 1))
        }

        return true;
    }

    array<InputCommand> Diff(const string &in bytes)
    {
        array<InputCommand> decoded;

        const uint len = bytes.Length;
        uint offset = len;
        for (uint i = MODE_SIZE; i < len; i += offset)
        {
            if (TestFlag(bytes[i], Op::Add))
            {
                //
            }
            else if (TestFlag(bytes[i], Op::Del))
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
            if (TestFlag(bytes[i], Op::Com))
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

namespace Data
{
    enum Op
    {
        Null,

        // Width of InputType
        Add = 1 << 4,
        Del = 1 << 5,
    }

    bool TestFlag(uint8 n, Op flag)
    {
        return n & flag == flag;
    }

    bool TestFlag(uint8 n, Op flag, Op cmp)
    {
        return n & flag == cmp;
    }

    array<uint8>@ FromString(const string &in str)
    {
        const uint len = str.Length;
        array<uint8> conv(len);
        for (uint i = 0; i < len; i++)
        {
            conv[i] = str[i];
        }
        return conv;
    }

    void IntoString(const array<uint8>@ const bytes, string& conv)
    {
        const uint len = bytes.Length;
        conv.Resize(len);
        for (uint i = 0; i < len; i++)
        {
            conv[i] = bytes[i];
        }
    }
}

class Data
{
    Data(const string &in str)
    {
        data = Data::FromString(str);
    }

    array<uint8> data;

    array<uint8>@ Slice(const uint ptr, const uint size) const
    {
        array<uint8> slice(size);
        for (uint i = 0; i < size; i++)
        {
            slice[i] = data[ptr + i];
        }
        return slice;
    }

    string opConv() const
    {
        string conv;
        Data::IntoString(data, conv);
        return conv;
    }
}

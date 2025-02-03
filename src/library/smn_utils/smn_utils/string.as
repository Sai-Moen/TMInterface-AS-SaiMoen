// smn_utils - v2.1.1a

/*

String
- padding
- string builder

*/


string PadLeft(const string &in str, const uint targetLength, const uint8 char = ' ')
{
    const uint len = str.Length;
    if (len >= targetLength)
        return str;

    string s;
    s.Resize(targetLength);

    const uint diff = targetLength - len;
    uint i;
    for (i = 0; i < diff; i++)
        s[i] = char;

    for (; i < targetLength; i++)
        s[i] = str[i - diff];

    return s;
}

string PadRight(const string &in str, const uint targetLength, const uint8 char = ' ')
{
    const uint len = str.Length;
    if (len >= targetLength)
        return str;

    string s = str;
    s.Resize(targetLength);

    for (uint i = len; i < targetLength; i++)
        s[i] = char;

    return s;
}

string Repeat(const uint8 char, const uint times)
{
    string builder;
    builder.Resize(times);
    for (uint i = 0; i < times; i++)
        builder[i] = char;
    return builder;
}

class StringBuilder
{
    protected array<string> buffer;

    // if you want to have array<StringBuilder>
    StringBuilder()
    {}

    StringBuilder(const string &in s)
    {
        Append(s);
    }

    StringBuilder(const array<string>@ strings)
    {
        buffer = strings;
    }

    void Append(const bool value)   { Append("" + value); }
    void Append(const uint value)   { Append("" + value); }
    void Append(const uint64 value) { Append("" + value); }
    void Append(const int value)    { Append("" + value); }
    void Append(const int64 value)  { Append("" + value); }
    void Append(const float value)  { Append("" + value); }
    void Append(const double value) { Append("" + value); }

    void Append(const string &in s)
    {
        buffer.Add(s);
    }

    void Append(const array<string>@ strings)
    {
        const uint len = buffer.Length;
        buffer.Resize(len + strings.Length);

        uint index = len;
        for (uint i = 0; i < strings.Length; i++)
            buffer[index++] = strings[i];
    }

    // using an output reference to avoid potentially multiple copies of a big string
    void ToString(string &out s) const
    {
        const uint len = buffer.Length;

        uint stringLength = 0;
        for (uint i = 0; i < len; i++)
            stringLength += buffer[i].Length;

        s.Resize(stringLength);
        uint index = 0;
        for (uint bufferIndex = 0; bufferIndex < len; bufferIndex++)
        {
            for (uint charIndex = 0; charIndex < buffer[bufferIndex].Length; charIndex++)
                s[index++] = buffer[bufferIndex][charIndex];
        }
    }

    void ToStringClear(string &out s)
    {
        ToString(s);
        buffer.Clear();
    }
}
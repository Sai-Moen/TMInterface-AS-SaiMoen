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

string Repeat(const uint times, const uint8 char = ' ')
{
    string builder;
    builder.Resize(times);
    for (uint i = 0; i < times; i++)
        builder[i] = char;
    return builder;
}

// avoids a bunch of string copies, at least if you pass around handles to it
// because string uses C++ std::string which is a value type that uses RAII and we don't have move semantics blablabla
class StringWrapper
{
    string str;

    // this is to allow array<StringWrapper>, though you could also just choose to use indices into array<string>
    StringWrapper()
    {}

    StringWrapper(const string &in s)
    {
        str = s;
    }
}

class StringBuilder
{
    protected string buffer;

    StringBuilder@ Append(const bool value)   { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const uint value)   { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const uint64 value) { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const int value)    { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const int64 value)  { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const float value)  { const string s = value; AppendOne(s); return this; }
    StringBuilder@ Append(const double value) { const string s = value; AppendOne(s); return this; }

    StringBuilder@ Append(const string &in value) { AppendOne(value); return this; }
    StringBuilder@ Append(const array<string>@ strings) { AppendMany(strings); return this; }

    StringBuilder@ AppendLine() { AppendOne("\n"); return this; }

    StringBuilder@ AppendLine(const bool value)   { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const uint value)   { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const uint64 value) { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const int value)    { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const int64 value)  { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const float value)  { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const double value) { AppendMany({value, "\n"}); return this; }

    StringBuilder@ AppendLine(const string &in value) { AppendMany({value, "\n"}); return this; }
    StringBuilder@ AppendLine(const array<string>@ strings)
    {
        AppendMany(strings, 1);
        buffer[buffer.Length - 1] = '\n';
        return this;
    }

    protected void AppendOne(const string &in s)
    {
        const uint offset = buffer.Length;
        buffer.Resize(offset + s.Length);
        for (uint i = 0; i < s.Length; i++)
            buffer[offset + i] = s[i];
    }

    protected void AppendMany(const array<string>@ strings, const uint extraLength = 0)
    {
        uint totalLength = extraLength;
        for (uint i = 0; i < strings.Length; i++)
            totalLength += strings[i].Length;

        const uint offset = buffer.Length;
        buffer.Resize(offset + totalLength);
        uint bufferIndex = offset;
        for (uint i = 0; i < strings.Length; i++)
        {
            for (uint j = 0; j < strings[i].Length; j++)
                buffer[bufferIndex++] = strings[i][j];
        }
    }

    void Clear()
    {
        buffer.Resize(0);
    }

    StringWrapper@ ToString() const
    {
        return StringWrapper(buffer);
    }

    StringWrapper@ ToStringClear()
    {
        const auto@ const sr = ToString();
        Clear();
        return sr;
    }
}

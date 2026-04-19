/*

smn_utils | String | v3.0.0

Features:
- String reference class
- String array helpers
- String helpers
- Character helpers

*/


// A reference type containing a 'string', which can be passed around by handle,
// in cases where return references do not suffice.
// Implicit conversions are defined to go to/from 'string' more easily,
// though with the risk of not helping compared to e.g. just returning the string directly.
class String
{
    string str;

    String() {}

    String(const string &in s)
    {
        str = s;
    }

    string& opImplConv()
    {
        return str;
    }
}

uint StringArrayCombinedLength(const array<string>@ strings)
{
    uint combined = 0;
    const uint len = strings.Length;
    for (uint i = 0; i < len; ++i)
        combined += strings[i].Length;
    return combined;
}

// To copy: string copy = StringPadLeft(string(s), lengthNew, c);
String@ StringPadLeft(string& s, const uint lengthNew, const uint8 c = ' ')
{
    const uint lengthOld = s.Length;
    if (lengthNew <= lengthOld)
        return s;

    s.Resize(lengthNew);

    const uint padBy = lengthNew - lengthOld;
    for (uint i = lengthNew - 1; i >= padBy; --i)
        s[i] = s[i - padBy];

    for (uint i = 0; i < padBy; ++i)
        s[i] = c;

    return s;
}

String@ StringPadLeftBy(string& s, const uint padBy, const uint8 c = ' ')
{
    return StringPadLeft(s, s.Length + padBy, c);
}

// To copy: string copy = StringPadRight(string(s), lengthNew, c);
String@ StringPadRight(string& s, const uint lengthNew, const uint8 c = ' ')
{
    const uint lengthOld = s.Length;
    if (lengthNew <= lengthOld)
        return s;

    s.Resize(lengthNew);

    for (uint i = lengthOld; i < lengthNew; ++i)
        s[i] = c;

    return s;
}

String@ StringPadRightBy(string& s, const uint padBy, const uint8 c = ' ')
{
    return StringPadRight(s, s.Length + padBy, c);
}

// Could also do Join, but that is built-in already.

String@ StringConcat(const array<string>@ strings, const uint extraLength = 0)
{
    string s;
    s.Resize(extraLength + StringArrayCombinedLength(strings));

    uint index = 0;
    const uint len = strings.Length;
    for (uint i = 0; i < len; ++i)
    {
        for (uint j = 0; j < strings[i].Length; ++j)
            s[index++] = strings[i][j];
    }

    return s;
}

String@ StringConcatWithPrefix(const array<string>@ strings, const string &in prefix, const uint extraLength = 0)
{
    string s;

    const uint len = strings.Length;
    s.Resize(extraLength + len + StringArrayCombinedLength(strings));

    uint index = 0;
    for (uint i = 0; i < len; ++i)
    {
        for (uint j = 0; j < prefix.Length; ++j)
            s[index++] = prefix[j];

        for (uint j = 0; j < strings[i].Length; ++j)
            s[index++] = strings[i][j];
    }

    return s;
}

String@ StringConcatWithPostfix(const array<string>@ strings, const string &in postfix, const uint extraLength = 0)
{
    string s;

    const uint len = strings.Length;
    s.Resize(extraLength + len + StringArrayCombinedLength(strings));

    uint index = 0;
    for (uint i = 0; i < len; ++i)
    {
        for (uint j = 0; j < strings[i].Length; ++j)
            s[index++] = strings[i][j];

        for (uint j = 0; j < postfix.Length; ++j)
            s[index++] = postfix[j];
    }

    return s;
}

uint StringGetLastLineLength(const string &in s)
{
    int right = s.Length - 1;
    while (right != -1)
    {
        if (s[right--] == '\n')
            break;
    }

    int left = right;
    while (left != -1)
    {
        if (s[left] == '\n')
            break;

        --left;
    }

    return right - left;
}

String@ CharRepeat(const uint times, const uint8 c = ' ')
{
    string s;
    s.Resize(times);
    for (uint i = 0; i < times; ++i)
        s[i] = c;
    return s;
}

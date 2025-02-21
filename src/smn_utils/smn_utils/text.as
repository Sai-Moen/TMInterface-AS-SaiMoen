// smn_utils - v2.1.1a

/*

Text
- parse wrappers
- precise format

*/


bool ParseFloat(const string &in s, double &out value)
{
    uint byteCount;
    value = Text::ParseFloat(s, byteCount);
    return byteCount != 0;
}

bool ParseInt(const string &in s, int64 &out value, const uint base = 10)
{
    uint byteCount;
    value = Text::ParseInt(s, base, byteCount);
    return byteCount != 0;
}

bool ParseUInt(const string &in s, uint64 &out value, const uint base = 10)
{
    uint byteCount;
    value = Text::ParseUInt(s, base, byteCount);
    return byteCount != 0;
}


string FormatPrecise(const double value, const uint precision = 12)
{
    return Text::FormatFloat(value, " ", 0, precision);
}

string FormatPrecise(const vec2 &in value, const uint precision = 12)
{
    const string x = FormatPrecise(value.x, precision);
    const string y = FormatPrecise(value.y, precision);

    string s;
    s.Resize(x.Length + 1 + y.Length);

    uint i = 0;
    for (uint j = 0; j < x.Length; j++)
        s[i++] = x[j];
    s[i++] = ' ';
    for (uint j = 0; j < y.Length; j++)
        s[i++] = y[j];

    return s;
}

string FormatPrecise(const vec3 &in value, const uint precision = 12)
{
    const string x = FormatPrecise(value.x, precision);
    const string y = FormatPrecise(value.y, precision);
    const string z = FormatPrecise(value.z, precision);

    string s;
    s.Resize(x.Length + 1 + y.Length + 1 + z.Length);

    uint i = 0;
    for (uint j = 0; j < x.Length; j++)
        s[i++] = x[j];
    s[i++] = ' ';
    for (uint j = 0; j < y.Length; j++)
        s[i++] = y[j];
    s[i++] = ' ';
    for (uint j = 0; j < z.Length; j++)
        s[i++] = z[j];

    return s;
}

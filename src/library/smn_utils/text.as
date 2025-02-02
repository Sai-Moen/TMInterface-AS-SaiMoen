// smn_utils - v2.1.0a

/*

Text
- Precise Format
- Parse wrappers

*/


// - Formatting
string PreciseFormat(const double value, const uint precision = 12)
{
    return Text::FormatFloat(value, " ", 0, precision);
}


// - Parsing
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

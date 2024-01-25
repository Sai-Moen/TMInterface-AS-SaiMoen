namespace smnu::Text
{
    /**
    * Tries to parse an unsigned integer in the given {string}.
    * @param s: the string to parse
    * @param &out u: the output unsigned integer
    * @param base: the base to use (10 by default)
    * @ret: whether the parser managed to find a number
    */
    shared bool TryParseUInt(const string &in s, uint64 &out u, const uint base = 10)
    {
        uint byteCount;
        u = Text::ParseUInt(s, base, byteCount);
        return byteCount > 0;
    }

    /**
    * Tries to parse an integer in the given {string}.
    * @param s: the string to parse
    * @param &out i: the output integer
    * @param base: the base to use (10 by default)
    * @ret: whether the parser managed to find a number
    */
    shared bool TryParseInt(const string &in s, int64 &out i, const uint base = 10)
    {
        uint byteCount;
        i = Text::ParseInt(s, base, byteCount);
        return byteCount > 0;
    }

    /**
    * Tries to parse a floating point number in the given {string}.
    * @param s: the string to parse
    * @param &out d: the output double
    * @ret: whether the parser managed to find a number
    */
    shared bool TryParseFloat(const string &in s, double &out d)
    {
        uint byteCount;
        d = Text::ParseFloat(s, byteCount);
        return byteCount > 0;
    }
}

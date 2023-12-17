namespace smnu::str
{
    // Stringifies the given parameter, of type T
    // param q: to stringify
    // returns: stringified parameter
    //  shared string ingify(const T q);

    shared string ingify(const bool b)    { const string s = b; return s; }
    shared string ingify(const uint u)    { const string s = u; return s; }
    shared string ingify(const uint64 ub) { const string s = ub; return s; }
    shared string ingify(const int i)     { const string s = i; return s; }
    shared string ingify(const int64 ib)  { const string s = ib; return s; }
    shared string ingify(const float f)   { const string s = f; return s; }
    shared string ingify(const double d)  { const string s = d; return s; }

    shared string ingify(const dictionaryValue dv)
    {
        const double defaultDouble = double(dictionaryValue());

        const double number = double(dv);
        if (number == defaultDouble)
        {
            // maybe number Conv failed, check for string representation
            const string s = string(dv);
            if (!s.IsEmpty())
            {
                return s;
            }
        }
        return ingify(number);
    }

    shared string ingify(const HandleStr@ const hstr) { return string(hstr); }
}

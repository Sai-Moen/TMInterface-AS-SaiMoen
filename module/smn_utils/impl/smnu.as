namespace smnu
{
    // Implement this to gain access to a special set of API's
    // These API's pass around handles and can check for identity
    shared interface Handle { }

    // Throws an exception and prints the given message
    // It is recommended to catch the exception somewhere
    // param exception: error message to log
    shared void Throw(const string &in exception)
    {
        const uint len = exception.Length;
        if (len > 0)
        {
            log(exception, Severity::Error);
        }
        const uint throw = len / (len ^ len); // fancy
    }

    // Stringifies the given primitive, of type T
    // param q: primitive to stringify
    // returns: stringified primitive
    //  shared string Stringify(const T q);

    shared string Stringify(const bool b)    { const string s = b; return s; }
    shared string Stringify(const uint u)    { const string s = u; return s; }
    shared string Stringify(const uint64 ub) { const string s = ub; return s; }
    shared string Stringify(const int i)     { const string s = i; return s; }
    shared string Stringify(const int64 ib)  { const string s = ib; return s; }
    shared string Stringify(const float f)   { const string s = f; return s; }
    shared string Stringify(const double d)  { const string s = d; return s; }

    shared string Stringify(const dictionaryValue dv)
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
        return Stringify(number);
    }
}

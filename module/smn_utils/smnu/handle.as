namespace smnu
{
    /**
    * Implement this on an object to gain access to a special set of API's.
    * These API's pass around handles and can check for identity.
    */
    shared interface Handle { }

    /**
    * This is an extended version of {Handle} that can be stringified.
    */
    shared interface Stringifiable : Handle
    {
        string opConv() const;
    }

    /**
    * This is an extended version of {Handle} that can make a hash of itself.
    */
    shared interface Hashable : Handle
    {
        uint hash() const;
    }

    /**
    * Casts a {dictionaryValue} to a {Handle@}.
    * @param dv: dictionary value
    * @ret: {Handle} object, null if cast failed
    */
    shared Handle@ CastToHandle(const dictionaryValue dv)
    {
        return cast<Handle@>(dv);
    }

    /**
    * Attempts to stringify a {const Handle@}.
    * @param h: {Handle} object
    * @param &out s: output {string}
    * @ret: whether |s| is a stringified version of |h|
    */
    shared bool TryStringifyHandle(const Handle@ const h, string &out s)
    {
        const auto@ const hstr = cast<const Stringifiable@>(h);
        const bool success = hstr !is null;
        if (success)
        {
            s = str::ingify(hstr);
        }
        return success;
    }
}

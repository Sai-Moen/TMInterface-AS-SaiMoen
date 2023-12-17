namespace smnu::dict
{
    // Called on each iteration with the dictionaryValue from the key
    shared funcdef void Iter(dictionaryValue&);

    shared void ForEach(dictionary@ const d, Iter@ const func)
    {
        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            func(d[keys[i]]);
        }
    }

    // Called on each iteration with the dictionary and key
    shared funcdef void IterKey(dictionary@ const, const string &in);

    shared void ForEachKey(dictionary@ const d, IterKey@ const funci)
    {
        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            funci(d, keys[i]);
        }
    }

    // Same as IterKey, but also returns a value
    shared funcdef dictionaryValue IterKeyVal(dictionary@ const, const string &in);

    shared array<dictionaryValue>@ ForEachKeyArr(dictionary@ const d, IterKeyVal@ const funcival)
    {
        array<dictionaryValue> values(d.GetSize());

        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            values[i] = funcival(d, keys[i]);
        }

        return values;
    }

    shared dictionary@ ForEachKeyDict(dictionary@ const d, IterKeyVal@ const funcival)
    {
        dictionary values;

        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            values[key] = funcival(d, key);
        }

        return values;
    }
}

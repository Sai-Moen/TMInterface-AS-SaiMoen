namespace smnu::Dict
{
    // Called on each iteration with the dictionary and key
    shared funcdef void Iter(dictionary@ const d, const string &in key);

    shared void ForEach(dictionary@ const d, const Iter@ const funci)
    {
        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            funci(d, keys[i]);
        }
    }

    // Same as Iter, but also returns a value
    shared funcdef dictionaryValue IterVal(dictionary@ const d, const string &in key);

    shared array<dictionaryValue>@ ForEachArr(dictionary@ const d, const IterVal@ const funcival)
    {
        array<dictionaryValue> values(d.GetSize());

        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            values[i] = funcival(d, keys[i]);
        }

        return values;
    }

    shared dictionary@ ForEachDict(dictionary@ const d, const IterVal@ const funcival)
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

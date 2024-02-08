namespace smnu::dict::DV
{
    /**
    * Called on each iteration with the {dictionaryValue} from the key.
    */
    shared funcdef void Iter(dictionaryValue&);

    // See handle.as
    shared void ForEach(dictionary@ const d, Iter@ const func)
    {
        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            func(d[keys[i]]);
        }
    }

    /**
    * Same as {IterKey}, but also returns a value.
    */
    shared funcdef dictionaryValue IterKeyVal(dictionary@, const string &in);

    // See handle.as
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

    // See handle.as
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

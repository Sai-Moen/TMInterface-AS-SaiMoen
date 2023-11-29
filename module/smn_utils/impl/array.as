namespace smnu::Array
{
    // Called on each iteration with the value from an index
    shared funcdef void Iter(string&);

    shared void ForEach(const array<string>@ const a, const Iter@ const func)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            func(a[i]);
        }
    }

    shared funcdef void Iter(dictionaryValue&);

    shared void ForEach(const array<dictionaryValue>@ const a, const Iter@ const func)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            func(a[i]);
        }
    }

    // Called on each iteration with the array and index
    shared funcdef void IterIdx(array<string>@ const, uint);

    shared void ForEachIdx(array<string>@ const a, const IterIdx@ const funci)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            funci(a, i);
        }
    }

    shared funcdef void IterIdx(array<dictionaryValue>@ const, uint);

    shared void ForEachIdx(array<dictionaryValue>@ const a, const IterIdx@ const funci)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            funci(a, i);
        }
    }

    // Same as IterIdx, but also returns a value
    shared funcdef string IterIdxVal(array<string>@ const, uint);

    shared array<string>@ ForEachIdxArr(array<string>@ const a, const IterIdxVal@ const funcival)
    {
        const uint len = a.Length;
        array<string> values(len);
        for (uint i = 0; i < len; i++)
        {
            values[i] = funcival(a, i);
        }
        return values;
    }

    shared funcdef dictionaryValue IterIdxVal(array<dictionaryValue>@ const, uint);

    shared array<dictionaryValue>@ ForEachIdxArr(array<dictionaryValue>@ const a, const IterIdxVal@ const funcival)
    {
        const uint len = a.Length;
        array<dictionaryValue> values(len);
        for (uint i = 0; i < len; i++)
        {
            values[i] = funcival(a, i);
        }
        return values;
    }
}

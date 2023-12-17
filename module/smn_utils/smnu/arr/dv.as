namespace smnu::arr::DV
{
    // Called on each iteration with the value from an index
    shared funcdef void Iter(dictionaryValue&);

    // See array docs
    shared void ForEach(array<dictionaryValue>@ const a, Iter@ const func)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            func(a[i]);
        }
    }

    // Called on each iteration with the array and index
    shared funcdef void IterIdx(array<dictionaryValue>@ const, uint);

    // See array docs
    shared void ForEachIdx(array<dictionaryValue>@ const a, IterIdx@ const funci)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            funci(a, i);
        }
    }

    // Same as IterIdx, but also returns a value
    shared funcdef dictionaryValue IterIdxVal(array<dictionaryValue>@ const, uint);

    // See array docs
    shared array<dictionaryValue>@ ForEachIdxArr(array<dictionaryValue>@ const a, IterIdxVal@ const funcival)
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

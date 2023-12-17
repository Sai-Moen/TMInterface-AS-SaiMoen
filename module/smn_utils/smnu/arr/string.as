namespace smnu::arr::str
{
    // Called on each iteration with the value from an index
    shared funcdef void Iter(string&);

    // See handle.as
    shared void ForEach(array<string>@ const a, Iter@ const func)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            func(a[i]);
        }
    }

    // Called on each iteration with the array and index
    shared funcdef void IterIdx(array<string>@ const, uint);

    // See handle.as
    shared void ForEachIdx(array<string>@ const a, IterIdx@ const funci)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            funci(a, i);
        }
    }

    // Same as IterIdx, but also returns a value
    shared funcdef string IterIdxVal(array<string>@ const, uint);

    // See handle.as
    shared array<string>@ ForEachIdxArr(array<string>@ const a, IterIdxVal@ const funcival)
    {
        const uint len = a.Length;
        array<string> values(len);
        for (uint i = 0; i < len; i++)
        {
            values[i] = funcival(a, i);
        }
        return values;
    }
}

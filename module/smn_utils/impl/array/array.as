namespace smnu::Array
{
    // Called on each iteration with the value from an index
    shared funcdef void Iter(Handle@);

    shared void ForEach(array<Handle@>@ const a, Iter@ const func)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            func(a[i]);
        }
    }

    // Called on each iteration with the array and index
    shared funcdef void IterIdx(array<Handle@>@ const, uint);

    shared void ForEachIdx(array<Handle@>@ const a, IterIdx@ const funci)
    {
        const uint len = a.Length;
        for (uint i = 0; i < len; i++)
        {
            funci(a, i);
        }
    }

    // Same as IterIdx, but also returns a value
    shared funcdef Handle@ IterIdxVal(array<Handle@>@ const, uint);

    shared array<Handle@>@ ForEachIdxArr(array<Handle@>@ const a, IterIdxVal@ const funcival)
    {
        const uint len = a.Length;
        array<Handle@> values(len);
        for (uint i = 0; i < len; i++)
        {
            @values[i] = funcival(a, i);
        }
        return values;
    }
}

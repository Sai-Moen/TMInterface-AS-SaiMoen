namespace smnu::arr
{
    // Called on each iteration with the value from an index
    shared funcdef void Iter(Handle@);

    // Calls func on each item in the array
    // param a: the array
    // param func: the function
    //  shared void ForEach(array<T>@ const, Iter@ const);

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

    // Calls func with the array and a valid index
    // param a: the array
    // param funci: the function
    //  shared void ForEachIdx(array<T>@ const, IterIdx@ const);

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

    // Similar to ForEachIdx, but also places a result in a new array
    // param a: the array
    // param funcival: the function
    // returns: the new array, constructed from the result of each function call
    //  shared array<T>@ ForEachIdxArr(array<T>@ const, IterIdxVal@ const);

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

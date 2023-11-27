namespace smnu::Arr::Str
{
    // Called on each iteration with the array and index
    shared funcdef void Iter(array<string>@ const a, const uint i);

    shared void ForEach(array<string>@ const a, const Iter@ const funci)
    {
        for (uint i = 0; i < a.Length; i++)
        {
            funci(a, i);
        }
    }

    // Same as Iter, but also returns a value
    shared funcdef string IterVal(array<string>@ const a, const uint i);

    shared array<string>@ ForEachArr(array<string>@ const a, const IterVal@ const funcival)
    {
        array<string> values(a.Length);
        for (uint i = 0; i < a.Length; i++)
        {
            values[i] = funcival(a, i);
        }
        return values;
    }
}

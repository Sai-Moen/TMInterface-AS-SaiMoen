namespace smnu::dict
{
    /**
    * Called on each iteration with the {Handle} from the key.
    */
    shared funcdef void Iter(Handle@);

    /**
    * Executes a function for each value in the {dictionary}.
    * @param d: dictionary to get values from
    * @param func: function to call on each value
    * @poly: shared void ForEach(dictionary@ const, Iter@ const);
    */

    shared void ForEach(dictionary@ const d, Iter@ const func)
    {
        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            func(CastToHandle(d[keys[i]]));
        }
    }

    /**
    * Same as {IterKey}, but also returns a value.
    */
    shared funcdef Handle@ IterKeyVal(dictionary@ const, const string &in);

    /**
    * Creates an array of the results of each IterKeyVal call.
    * @param d: dictionary to use
    * @param funcival: function to call on each key
    * @ret: array of resulting Handles
    * @poly: shared array<T>@ ForEachKeyArr(dictionary@ const, IterKeyVal@ const);
    */

    shared array<Handle@>@ ForEachKeyArr(dictionary@ const d, IterKeyVal@ const funcival)
    {
        array<Handle@> values(d.GetSize());

        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            @values[i] = funcival(d, keys[i]);
        }

        return values;
    }

    /**
    * Creates a dictionary of the results of each IterKeyVal call.
    * @param d: dictionary to use
    * @param funcival: function to call on each key
    * @ret: dictionary of results
    * @poly: shared dictionary@ ForEachKeyDict(dictionary@ const, IterKeyVal@ const);
    */

    shared dictionary@ ForEachKeyDict(dictionary@ const d, IterKeyVal@ const funcival)
    {
        dictionary values;

        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            const string key = keys[i];
            @values[key] = funcival(d, key);
        }

        return values;
    }
}

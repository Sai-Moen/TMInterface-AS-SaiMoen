namespace smnu::dict
{
    /**
    * Called on each iteration with the {dictionary} and key.
    */
    shared funcdef void IterKey(dictionary@, const string &in);

    /**
    * Executes a function for each key, giving the {dictionary} and key to the function.
    * @param d: {dictionary} to use
    * @param funci: function to call with {dictionary} and a key
    */
    shared void ForEachKey(dictionary@ const d, IterKey@ const funci)
    {
        const array<string>@ const keys = d.GetKeys();
        for (uint i = 0; i < keys.Length; i++)
        {
            funci(d, keys[i]);
        }
    }
}

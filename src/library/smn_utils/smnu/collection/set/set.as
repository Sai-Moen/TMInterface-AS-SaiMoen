namespace smnu
{
    /**
    * Represents a mathematical set.
    */
    shared interface Set : Collection
    {
        /**
        * Adds an element to this {Set}, if it was not already there.
        * @param handle: the handle to add
        * @ret: whether this operation changed the {Set}
        */
        bool Add(Handle@ handle);

        /**
        * Removes an element from this {Set}, without anything happening if it was not there.
        * @param handle: the handle to remove
        * @ret: whether this operation changed the {Set}
        */
        bool Remove(Handle@ handle);
    }
}

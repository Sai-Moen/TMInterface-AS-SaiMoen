namespace smnu
{
    /**
    * Represents a mathematical set.
    */
    shared interface Set : Handle
    {
        /**
        * Whether this {Set} is empty (i.e. has no elements).
        */
        bool IsEmpty { get const; }

        /**
        * The size of this {Set} (i.e. # of elements).
        */
        uint Size { get const; }


        /**
        * Returns if |handle| is in the {Set}.
        * @param handle: the handle
        * @ret: whether this {Set} contains the given {Handle}
        */
        bool Contains(Handle@ handle) const;


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

        /**
        * Clears the {Set}; removes the reference to each element,
        * the {Set} does not necessarily become empty, but all remaining elements will be null.
        */
        void Clear();
    }
}

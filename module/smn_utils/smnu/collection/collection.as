namespace smnu
{
    /**
    * Represents a collection of elements.
    */
    shared interface Collection : Handle
    {
        /**
        * Whether this {Collection} is empty; has no elements.
        */
        bool IsEmpty { get const; }

        /**
        * The size of this {Collection}; # of elements.
        */
        uint Size { get const; }

        /**
        * Clears the {Collection}; removes the reference to each element.
        */
        void Clear();


        /**
        * Returns if |handle| is in the {Collection}.
        * @param handle: the handle
        * @ret: whether this {Collection} contains the given {Handle}
        */
        bool Contains(Handle@ handle) const;
    }
}

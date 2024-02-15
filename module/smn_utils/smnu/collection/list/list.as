namespace smnu
{
    /**
    * Represents a list; an indexed, ordered sequence of elements.
    */
    shared interface List : Collection
    {
        /**
        * Gets the {Handle} at |index|.
        * @param index: the index
        * @ret: the {Handle} at the given index
        */
        Handle@ get_opIndex(const uint index) const; // implement as property

        /**
        * Sets the {Handle} at |index|.
        * @param index: the index
        * @param value: the new {Handle} at the given index
        */
        void set_opIndex(const uint index, Handle@ value); // implement as property

        /**
        * Resizes this {List} to have the given length.
        * @param length: the length
        */
        void Resize(const uint length);


        /**
        * Adds the given {Handle} to the end of this {List}.
        * @param handle: the {Handle} to add
        */
        void Add(Handle@ handle);

        /**
        * Inserts the given {Handle} at |index|.
        * @param index: the index to insert at
        * @param handle: the {Handle} to insert at the given index
        */
        void InsertAt(const uint index, Handle@ handle);

        /**
        * Removes all instances of the given {Handle} from this {List}.
        * @param handle: the {Handle} to remove
        */
        void Remove(Handle@ handle);

        /**
        * Removes |count| number of elements, starting at |index|.
        * @param index: the index to start at
        * @param count: the number of elements to remove
        */
        void RemoveAt(const uint index, const uint count = 1);


        /**
        * Finds |handle| in this {List}, returns an index.
        * @param handle: the handle
        * @ret: index of |handle|, negative if not found
        */
        int Find(Handle@ handle) const;

        /**
        * Finds |handle| in this {List}, starting at |startAt|, returns an index.
        * @param startAt: where to start at
        * @param handle: the handle
        * @ret: index of |handle|, negative if not found
        */
        int Find(const uint startAt, Handle@ handle) const;

        /**
        * Sorts this {List} in ascending order.
        */
        void SortAsc();

        /**
        * Sorts this {List} in descending order.
        */
        void SortDesc();
    }
}

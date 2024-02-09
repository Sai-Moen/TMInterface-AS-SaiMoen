namespace smnu
{
    /**
    * Represents a queue; a FIFO sequence of elements.
    */
    shared interface Queue : Collection
    {
        /**
        * Returns if |handle| is in the {Queue}.
        * @param handle: the handle
        * @ret: whether this {Queue} contains the given {Handle}
        */
        bool Contains(Handle@ handle) const;

        /**
        * Returns the first element in this {Queue}, null if empty.
        * @ret: First element, still queued
        */
        Handle@ Peek() const;


        /**
        * Adds |handle| to the end of this {Queue}.
        * @param handle: handle to add
        */
        void Enqueue(Handle@ handle);

        /**
        * Removes the first element from this {Queue} and returns it, null if empty.
        * @ret: First element, no longer queued
        */
        Handle@ Dequeue();
    }
}

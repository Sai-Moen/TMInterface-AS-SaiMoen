namespace smnu
{
    /**
    * Represents a stack; a LIFO sequence of elements.
    */
    shared interface Stack : Collection
    {
        /**
        * Returns the element at the top of this {Stack}, null if empty.
        * @ret: top of stack, does not remove it
        */
        Handle@ Peek() const;


        /**
        * Pushes an element onto this {Stack}.
        * @param handle: the element to push
        */
        void Push(Handle@ handle);

        /**
        * Pops an element from this {Stack}, null if empty.
        * @ret: top of stack, also removes it
        */
        Handle@ Pop();
    }
}

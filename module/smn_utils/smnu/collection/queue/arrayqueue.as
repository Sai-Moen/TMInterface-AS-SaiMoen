namespace smnu::queues
{
    /**
    * A {Queue} based on an array.
    */
    shared class ArrayQueue : Queue
    {
        private const uint DEFAULT_SIZE { get const { return 8; } }

        ArrayQueue(const uint init = DEFAULT_SIZE) explicit
        {
            elements(init);
        }

        protected array<Handle@> elements;

        bool IsEmpty { get const override { return elements.IsEmpty(); } }
        uint Size { get const override { return elements.Length; } }

        bool Contains(Handle@ handle) const override
        {
            return elements.Find(handle) >= 0;
        }

        Handle@ Peek() const override
        {
            if (IsEmpty) return null;
            else return elements[0];
        }

        void Enqueue(Handle@ handle) override
        {
            elements.Add(handle);
        }

        Handle@ Dequeue() override
        {
            Handle@ const handle = Peek();
            if (handle !is null)
            {
                elements.RemoveAt(0);
            }
            return handle;
        }

        void Clear() override
        {
            elements.Clear();
        }
    }
}

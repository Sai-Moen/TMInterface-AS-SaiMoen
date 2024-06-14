namespace smnu::lists
{
    /**
    * A {List} based on an array.
    */
    shared class ArrayList : List
    {
        ArrayList()
        {
            elements = array<Handle@>();
        }

        ArrayList(const uint size)
        {
            elements = array<Handle@>(size);
        }

        protected array<Handle@> elements;

        bool IsEmpty { get const override { return elements.IsEmpty(); } }
        uint Size { get const override { return elements.Length; } }

        Handle@ get_opIndex(const uint index) const property override
        {
            return elements[index];
        }

        void set_opIndex(const uint index, Handle@ value) property override
        {
            @elements[index] = value;
        }

        void Resize(const uint length) override
        {
            elements.Resize(length);
        }

        bool Contains(Handle@ handle) const override
        {
            return Find(handle) >= 0;
        }

        void Add(Handle@ handle) override
        {
            elements.Add(handle);
        }

        void InsertAt(const uint index, Handle@ handle) override
        {
            elements.InsertAt(index, handle);
        }

        void Remove(Handle@ handle) override
        {
            for (uint i = 0; i < Size; i++)
            {
                if (this[i] is handle) RemoveAt(i);
            }
        }

        void RemoveAt(const uint index, const uint count = 1) override
        {
            elements.RemoveAt(index, count);
        }

        void Clear() override
        {
            elements.Clear();
        }

        int Find(Handle@ handle) const override
        {
            return elements.Find(handle);
        }

        int Find(const uint startAt, Handle@ handle) const override
        {
            return elements.Find(startAt, handle);
        }

        void SortAsc() override
        {
            elements.SortAsc();
        }

        void SortDesc() override
        {
            elements.SortDesc();
        }
    }
}

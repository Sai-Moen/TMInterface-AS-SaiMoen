namespace smnu::sets
{
    /*
    * A Set implementation backed by an array.
    */
    shared class ArraySet : Set
    {
        private const uint DEFAULT_SIZE { get const { return 16; } }

        ArraySet(const uint init = DEFAULT_SIZE) explicit
        {
            elements = array<Handle@>(init);
        }

        protected array<Handle@> elements;
        
        bool IsEmpty { get const override { return elements.IsEmpty(); } }
        uint Size { get const override { return elements.Length; } }

        bool Contains(Handle@ handle) const override
        {
            return IsValidFindIndex(elements.Find(handle));
        }

        bool Add(Handle@ handle) override
        {
            const bool changing = !Contains(handle);
            if (changing)
            {
                elements.Add(handle);
            }
            return changing;
        }

        bool Remove(Handle@ handle) override
        {
            const int index = elements.Find(handle);
            if (!IsValidFindIndex(index)) return false;

            elements.RemoveAt(index);
            return true;
        }

        void Clear() override
        {
            elements.Clear();
        }

        protected bool IsValidFindIndex(const int index) const
        {
            return index >= 0;
        }
    }
}

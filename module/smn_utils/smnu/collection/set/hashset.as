namespace smnu::sets
{
    /**
    * A Set implementation based on {Hashable} objects' hashing.
    */
    shared class HashSet : Set
    {
        private const uint DEFAULT_SIZE { get const { return 16; } }

        HashSet(const uint size = DEFAULT_SIZE) explicit
        {
            @elements = array<Hashable@>(size);
        }

        protected array<Hashable@>@ elements;

        bool IsEmpty { get const override { return elements.IsEmpty(); } }
        uint Size { get const override { return elements.Length; } }

        bool Contains(Handle@ handle) const override
        {
            Hashable@ hashable;
            if (!TryCastHandle(handle, @hashable)) return false;

            const uint index = FindValidIndex(hashable);
            return elements[index] !is null;
        }

        bool Add(Handle@ handle) override
        {
            Hashable@ hashable;
            if (!TryCastHandle(handle, @hashable)) return false;

            const uint index = FindValidIndex(hashable);
            if (elements[index] !is null) return false;

            @elements[index] = hashable;
            return true;
        }

        bool Remove(Handle@ handle) override
        {
            Hashable@ hashable;
            if (!TryCastHandle(handle, @hashable)) return false;

            const uint index = FindValidIndex(hashable);
            @elements[index] = null;

            Shrink();
            return true;
        }

        void Clear() override
        {
            @elements = array<Hashable@>(DEFAULT_SIZE);
        }

        protected bool TryCastHandle(Handle@ const handle, Hashable@ &out hashable) const
        {
            @hashable = cast<Hashable@>(handle);
            return hashable !is null;
        }

        protected uint FindValidIndex(Hashable@ const h) const
        {
            for (uint i = h.hash() % elements.Length; i < elements.Length; i++)
            {
                Hashable@ const other = elements[i];
                if (other is null || other is h) return i;
            }

            Enlarge();
            return FindValidIndex(h);
        }

        protected void Shrink()
        {
            uint filled = 0;
            for (uint i = 0; i < elements.Length; i++)
            {
                filled += elements[i] is null ? 0 : 1;
            }

            const uint threshold = elements.Length >> 2;
            if (filled < threshold)
            {
                RecalculateHashes(elements.Length >> 1);
            }
        }

        protected void Enlarge()
        {
            RecalculateHashes(elements.Length << 1);
        }

        protected void RecalculateHashes(const uint len)
        {
            array<Hashable@> recalc(len < DEFAULT_SIZE ? DEFAULT_SIZE : len);
            for (uint i = 0; i < elements.Length; i++)
            {
                Hashable@ const h = elements[i];
                if (h !is null) @recalc[FindValidIndex(h)] = h;
            }
            @elements = recalc;
        }
    }
}

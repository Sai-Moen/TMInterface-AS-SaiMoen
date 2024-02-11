namespace smnu::bitsets
{
    /**
    * A dynamically allocated {BitSet}.
    * Backed by {BitSet32}.
    */
    shared class DynamicBitSet : BitSet
    {
        protected const uint WIDTH { get const { return 0x20; } }

        DynamicBitSet(const uint init = 0) explicit
        {
            Resize(init);
        }

        array<BitSet32> bitsArray;

        uint Length { get const { return bitsArray.Length; } }
        uint Size { get const override { return Length * WIDTH; } }

        protected uint GetRelativeIndex(const uint index) const
        {
            return index & 0x1f;
        }

        protected uint GetArrayIndex(const uint index) const
        {
            return index >> 5;
        }

        protected bool CheckCompatible(const BitSet@ const other, const DynamicBitSet@ &out value)
        {
            const bool sizeCompatible = Size == other.Size;
            if (sizeCompatible) @value = cast<const DynamicBitSet@>(other);
            return sizeCompatible;
        }

        protected BitSet32 CastToBacking(BitSet@ const value)
        {
            return cast<BitSet32>(value);
        }

        void Resize(const uint size)
        {
            bitsArray.Resize(GetArrayIndex(size));
        }

        BitSet@ Copy() const override
        {
            DynamicBitSet copy;
            copy.bitsArray = bitsArray;
            return copy;
        }

        bool opEquals(const BitSet@ &in other) const override
        {
            const DynamicBitSet@ b;
            if (!CheckCompatible(other, @b)) return false;

            for (uint i = 0; i < Length; i++)
            {
                if (bitsArray[i] != b.bitsArray[i]) return false;
            }
            return true;
        }

        bool Get(const uint index) const override
        {
            if (index >= Size) return false;

            const BitSet32 bv = bitsArray[GetArrayIndex(index)];
            return bv.Get(GetRelativeIndex(index));
        }

        void Set(const uint index, const bool value) override
        {
            if (index >= Size) Resize(index);
            BitSet32@ const bv = bitsArray[GetArrayIndex(index)];
            bv.Set(GetRelativeIndex(index), value);
        }

        void Reset() override
        {
            for (uint i = 0; i < Length; i++)
            {
                bitsArray[i].Reset();
            }
        }

        void Reset(const uint index) override
        {
            if (index >= Size) return;

            BitSet32@ const bv = bitsArray[GetArrayIndex(index)];
            bv.Reset(GetRelativeIndex(index));
        }

        void Flip() override
        {
            for (uint i = 0; i < Length; i++)
            {
                bitsArray[i].Flip();
            }
        }

        void Flip(const uint index) override
        {
            if (index >= Size) return;
            
            BitSet32@ const bv = bitsArray[GetArrayIndex(index)];
            bv.Flip(GetRelativeIndex(index));
        }

        BitSet@ opCom() const override
        {
            BitSet@ const copy = Copy();
            copy.Flip();
            return copy;
        }

        BitSet@ opAnd(const BitSet@ const right) const override
        {
            const DynamicBitSet@ b;
            if (!CheckCompatible(right, @b)) return null;

            DynamicBitSet copy;
            copy.Resize(Length);
            for (uint i = 0; i < Length; i++)
            {
                copy.bitsArray[i] = CastToBacking(bitsArray[i] & b.bitsArray[i]);
            }
            return copy;
        }

        BitSet@ opOr(const BitSet@ const right) const override
        {
            const DynamicBitSet@ b;
            if (!CheckCompatible(right, @b)) return null;

            DynamicBitSet copy;
            copy.Resize(Length);
            for (uint i = 0; i < Length; i++)
            {
                copy.bitsArray[i] = CastToBacking(bitsArray[i] | b.bitsArray[i]);
            }
            return copy;
        }

        BitSet@ opXor(const BitSet@ const right) const override
        {
            const DynamicBitSet@ b;
            if (!CheckCompatible(right, @b)) return null;

            DynamicBitSet copy;
            copy.Resize(Length);
            for (uint i = 0; i < Length; i++)
            {
                copy.bitsArray[i] = CastToBacking(bitsArray[i] ^ b.bitsArray[i]);
            }
            return copy;
        }

        string opConv() const override
        {
            string builder;
            for (uint i = 0; i < Length; i++)
            {
                builder += string(bitsArray[i]) + "\n";
            }
            return builder;
        }
    }
}

namespace smnu::bitsets
{
    /*
    * Common fixed-size elements (note: mixins cannot be shared).
    */
    mixin class FixedBitSet : smnu::BitSet // why is this needed, probably some bug with mixin
    {
        protected uint FromBool(const bool b) const
        {
            return b ? 1 : 0;
        }

        BitSet@ Copy() const override
        {
            return TrueCopy();
        }

        bool opEquals(const BitSet@ &in other) const override
        {
            const auto@ const b = Cast(other);
            if (b is null) return false;
            else return bits == b.bits;
        }

        bool Get(const uint index) const override
        {
            return bits & Shifted(index) != ZERO;
        }

        void Set(const uint index, const bool value) override
        {
            Reset(index);
            bits |= Shifted(index, value);
        }

        void Reset() override
        {
            bits &= ZERO;
        }

        void Reset(const uint index) override
        {
            bits &= ~Shifted(index);
        }

        void Flip() override
        {
            bits ^= ~ZERO;
        }

        void Flip(const uint index) override
        {
            bits ^= Shifted(index);
        }

        BitSet@ opCom() const override
        {
            BitSet@ copy = Copy();
            copy.Flip();
            return copy;
        }

        BitSet@ opAnd(const BitSet@ const right) const override
        {
            const auto@ const r = Cast(right);
            if (r is null) return null;

            auto copy = TrueCopy();
            copy.bits &= r.bits;
            return copy;
        }

        BitSet@ opOr(const BitSet@ const right) const override
        {
            const auto@ const r = Cast(right);
            if (r is null) return null;

            auto copy = TrueCopy();
            copy.bits |= r.bits;
            return copy;
        }

        BitSet@ opXor(const BitSet@ const right) const override
        {
            const auto@ const r = Cast(right);
            if (r is null) return null;

            auto copy = TrueCopy();
            copy.bits ^= r.bits;
            return copy;
        }

        string opConv() const override
        {
            string builder;
            for (uint i = 0; i < Size; i++)
            {
                if (i & 3 == 0) builder += " ";
                builder += FromBool(Get(i));
            }
            return builder;
        }
    }

    /**
    * 8-bit {BitSet}.
    */
    shared class BitSet8 : FixedBitSet
    {
        const uint8 ZERO { get const { return 0; } }
        protected uint8 bits = 0;
        uint Size { get const override { return 0x8; } }

        protected uint8 Shifted(const uint index, const bool value = true) const
        {
            return uint8(FromBool(value)) << index;
        }

        protected const BitSet8@ Cast(const BitSet@ other)
        {
            return cast<const BitSet8@>(other);
        }

        protected BitSet8 TrueCopy() const
        {
            BitSet8 copy;
            copy.bits = bits;
            return copy;
        }
    }

    /**
    * 16-bit {BitSet}.
    */
    shared class BitSet16 : FixedBitSet
    {
        const uint16 ZERO { get const { return 0; } }
        protected uint16 bits = 0;
        uint Size { get const override { return 0x10; } }

        protected uint16 Shifted(const uint index, const bool value = true) const
        {
            return uint16(FromBool(value)) << index;
        }

        protected const BitSet16@ Cast(const BitSet@ other)
        {
            return cast<const BitSet16@>(other);
        }

        protected BitSet16 TrueCopy() const
        {
            BitSet16 copy;
            copy.bits = bits;
            return copy;
        }
    }

    /**
    * 32-bit {BitSet}.
    */
    shared class BitSet32 : FixedBitSet
    {
        const uint32 ZERO { get const { return 0; } }
        protected uint32 bits = 0;
        uint Size { get const override { return 0x20; } }

        protected uint32 Shifted(const uint index, const bool value = true) const
        {
            return uint32(FromBool(value)) << index;
        }

        protected const BitSet32@ Cast(const BitSet@ other)
        {
            return cast<const BitSet32@>(other);
        }

        protected BitSet32 TrueCopy() const
        {
            BitSet32 copy;
            copy.bits = bits;
            return copy;
        }
    }

    /**
    * 64-bit {BitSet}.
    */
    shared class BitSet64 : FixedBitSet
    {
        const uint64 ZERO { get const { return 0; } }
        protected uint64 bits = 0;
        uint Size { get const override { return 0x40; } }

        protected uint64 Shifted(const uint index, const bool value = true) const
        {
            return uint64(FromBool(value)) << index;
        }

        protected const BitSet64@ Cast(const BitSet@ other)
        {
            return cast<const BitSet64@>(other);
        }

        protected BitSet64 TrueCopy() const
        {
            BitSet64 copy;
            copy.bits = bits;
            return copy;
        }
    }
}

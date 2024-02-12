namespace smnu::bitsets
{
    /*
    * Common fixed-size elements (note: mixins cannot be shared).
    */
    mixin class StaticBitSet : smnu::BitSet // why is this needed, probably some bug with mixin
    {
        bool get_opIndex(const uint index) const property override
        {
            return Bits & Shifted(index) != ZERO;
        }

        void set_opIndex(const uint index, const bool value) property override
        {
            Reset(index);
            bits |= Shifted(index, value);
        }

        BitSet@ Copy() const override
        {
            return TrueCopy();
        }

        bool opEquals(const BitSet@ &in other) const override
        {
            const auto@ const b = Cast(other);
            if (b is null) return false;
            else return Bits == b.Bits;
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

        protected BitSet@ DoBinary(const BitSet@ const other, const BinaryOperation@ const op) const
        {
            const auto@ const r = Cast(other);
            if (r is null) return null;

            auto copy = TrueCopy();
            copy.bits = op(copy, r);
            return copy;
        }

        BitSet@ opAnd(const BitSet@ const other) const override
        {
            return DoBinary(other, function(t, b) { return t.Bits & b.Bits; } );
        }

        BitSet@ opOr(const BitSet@ const other) const override
        {
            return DoBinary(other, function(t, b) { return t.Bits | b.Bits; } );
        }

        BitSet@ opXor(const BitSet@ const other) const override
        {
            return DoBinary(other, function(t, b) { return t.Bits ^ b.Bits; } );
        }

        string opConv() const override
        {
            string builder;
            for (uint i = 0; i < Size; i++)
            {
                if (i & 3 == 0) builder += " ";
                builder += FromBool(this[i]);
            }
            return builder;
        }

        protected uint FromBool(const bool b) const
        {
            return b ? 1 : 0;
        }
    }

    /**
    * 8-bit {BitSet}.
    */
    shared class BitSet8 : StaticBitSet
    {
        const uint8 ZERO { get const { return 0; } }

        protected uint8 bits = 0;
        uint8 Bits { get const { return bits; } }

        uint Size { get const override { return 0x8; } }

        protected uint8 Shifted(const uint index, const bool value = true) const
        {
            return uint8(FromBool(value)) << index;
        }

        funcdef uint8 BinaryOperation(const BitSet8, const BitSet8@ const);

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
    shared class BitSet16 : StaticBitSet
    {
        const uint16 ZERO { get const { return 0; } }

        protected uint16 bits = 0;
        uint16 Bits { get const { return bits; } }

        uint Size { get const override { return 0x10; } }

        protected uint16 Shifted(const uint index, const bool value = true) const
        {
            return uint16(FromBool(value)) << index;
        }

        funcdef uint16 BinaryOperation(const BitSet16, const BitSet16@ const);

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
    shared class BitSet32 : StaticBitSet
    {
        const uint32 ZERO { get const { return 0; } }

        protected uint32 bits = 0;
        uint32 Bits { get const { return bits; } }

        uint Size { get const override { return 0x20; } }

        protected uint32 Shifted(const uint index, const bool value = true) const
        {
            return uint32(FromBool(value)) << index;
        }

        funcdef uint32 BinaryOperation(const BitSet32, const BitSet32@ const);

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
    shared class BitSet64 : StaticBitSet
    {
        const uint64 ZERO { get const { return 0; } }

        protected uint64 bits = 0;
        uint64 Bits { get const { return bits; } }

        uint Size { get const override { return 0x40; } }

        protected uint64 Shifted(const uint index, const bool value = true) const
        {
            return uint64(FromBool(value)) << index;
        }

        funcdef uint64 BinaryOperation(const BitSet64, const BitSet64@ const);

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

namespace smnu
{
    /**
    * An interface shared by all {BitVector}s.
    */
    shared interface BitVector : Stringifiable
    {
        bool Get(const uint index) const;
        void Set(const uint index, const bool value);
    }

    /**
    * A dynamically allocated {BitVector}.
    * Backed by {BitVector32}.
    */
    shared class BitVectorDynamic : BitVector
    {
        const uint WIDTH { get const { return 0x20; } }

        BitVectorDynamic(const uint length)
        {
            Resize(length);
        }

        array<BitVector32> bitsArray;

        bool Get(const uint index) const
        {
            if (index > Length)
            {
                return false;
            }

            const BitVector32 bv = bitsArray[GetArrayIndex(index)];
            return bv.Get(GetRelativeIndex(index));
        }

        void Set(const uint index, const bool value)
        {
            if (index > Length)
            {
                Resize(index + 1);
            }

            BitVector32@ const bv = bitsArray[GetArrayIndex(index)];
            bv.Set(GetRelativeIndex(index), value);
        }

        uint Length { get const { return bitsArray.Length * WIDTH; } }

        void Resize(const uint length)
        {
            bitsArray.Resize(GetArrayIndex(length - 1) + 1);
        }

        protected uint GetRelativeIndex(const uint index) const
        {
            return index & 0x1f;
        }

        protected uint GetArrayIndex(const uint index) const
        {
            return index >> 5;
        }

        string opConv() const
        {
            string builder;
            for (uint i = 0; i < bitsArray.Length; i++)
            {
                builder += bitsArray[i].opConv() + "\n";
            }
            return builder;
        }
    }

    /**
    * A static {BitVector} that picks an underlying data structure based on the given size.
    */
    shared class BitVectorStatic : BitVector
    {
        BitVectorStatic(const uint size)
        {
            if (size <= 8)
            {
                @bits = BitVector8();
            }
            else if (size <= 16)
            {
                @bits = BitVector16();
            }
            else if (size <= 32)
            {
                @bits = BitVector32();
            }
            else if (size <= 64)
            {
                @bits = BitVector64();
            }
            else
            {
                Throw("Tried to allocate BitVectorStatic larger than allowed: " + size + " > 64");
            }
        }

        BitVector@ bits;

        bool Get(const uint index) const
        {
            return bits.Get(index);
        }

        void Set(const uint index, const bool value)
        {
            bits.Set(index, value);
        }

        string opConv() const
        {
            return bits.opConv();
        }
    }

    // common fixed-size elements captured in here
    mixin class BitVectorMixin : BitVector
    {
        bool Get(const uint index) const
        {
            const auto shift = Shifted(index);
            return bits & shift == shift;
        }

        void Set(const uint index, const bool value)
        {
            bits = (bits & ~Shifted(index)) | Shifted(index, value);
        }

        uint FromBool(const bool b) const
        {
            return b ? 1 : 0;
        }

        string opConv() const
        {
            string builder;
            for (uint i = 0; i < WIDTH; i++)
            {
                if (i & 3 == 0) builder += " ";
                builder += FromBool(Get(i));
            }
            return builder;
        }
    }

    /**
    * 8-bit {BitVector}.
    */
    shared class BitVector8 : BitVectorMixin
    {
        const uint WIDTH { get const { return 0x8; } }

        uint8 bits = 0;

        uint8 Convert(const uint8 c) const
        {
            return uint8(c);
        }

        uint8 Shifted(const uint index, const bool shift = true) const
        {
            return Convert(FromBool(shift)) << index;
        }
    }

    /**
    * 16-bit {BitVector}.
    */
    shared class BitVector16 : BitVectorMixin
    {
        const uint WIDTH { get const { return 0x10; } }

        uint16 bits = 0;

        uint16 Convert(const uint16 c) const
        {
            return uint16(c);
        }

        uint16 Shifted(const uint index, const bool shift = true) const
        {
            return Convert(FromBool(shift)) << index;
        }
    }

    /**
    * 32-bit {BitVector}.
    */
    shared class BitVector32 : BitVectorMixin
    {
        const uint WIDTH { get const { return 0x20; } }

        uint32 bits = 0;

        uint32 Convert(const uint32 c) const
        {
            return uint32(c);
        }

        uint32 Shifted(const uint index, const bool shift = true) const
        {
            return Convert(FromBool(shift)) << index;
        }
    }

    /**
    * 64-bit {BitVector}.
    */
    shared class BitVector64 : BitVectorMixin
    {
        const uint WIDTH { get const { return 0x40; } }

        uint64 bits = 0;

        uint64 Convert(const uint64 c) const
        {
            return uint64(c);
        }

        uint64 Shifted(const uint index, const bool shift = true) const
        {
            return Convert(FromBool(shift)) << index;
        }
    }
}

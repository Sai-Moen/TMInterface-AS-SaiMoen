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

        bool get_opIndex(const uint index) const property override
        {
            if (index >= Size) return false;
            else return bitsArray[ArrayIndex(index)][RelativeIndex(index)];
        }

        void set_opIndex(const uint index, const bool value) property override
        {
            if (index >= Size) Resize(index);
            bitsArray[ArrayIndex(index)][RelativeIndex(index)] = value;
        }

        protected uint ArrayIndex(const uint index) const
        {
            return index >> 5;
        }

        protected uint RelativeIndex(const uint index) const
        {
            return index & 0x1f;
        }

        void Resize(const uint size)
        {
            bitsArray.Resize(ArrayIndex(size));
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

        protected bool CheckCompatible(const BitSet@ const other, const DynamicBitSet@ &out value)
        {
            const bool sizeCompatible = Size == other.Size;
            if (sizeCompatible) @value = cast<const DynamicBitSet@>(other);
            return sizeCompatible;
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

            BitSet32@ const bv = bitsArray[ArrayIndex(index)];
            bv.Reset(RelativeIndex(index));
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
            
            BitSet32@ const bv = bitsArray[ArrayIndex(index)];
            bv.Flip(RelativeIndex(index));
        }

        BitSet@ opCom() const override
        {
            BitSet@ const copy = Copy();
            copy.Flip();
            return copy;
        }

        funcdef BitSet@ BinaryOperation(const BitSet32, const BitSet32);

        protected BitSet@ DoBinary(const BitSet@ const other, BinaryOperation@ const op)
        {
            const DynamicBitSet@ b;
            if (!CheckCompatible(other, @b)) return null;

            DynamicBitSet copy;
            copy.Resize(Length);
            for (uint i = 0; i < Length; i++)
            {
                copy.bitsArray[i] = cast<BitSet32>(op(bitsArray[i], b.bitsArray[i]));
            }
            return copy;
        }

        BitSet@ opAnd(const BitSet@ const other) const override
        {
            return DoBinary(other, function(t, b) { return t & b; } );
        }

        BitSet@ opOr(const BitSet@ const other) const override
        {
            return DoBinary(other, function(t, b) { return t | b; } );
        }

        BitSet@ opXor(const BitSet@ const other) const override
        {
            return DoBinary(other, function(t, b) { return t ^ b; } );
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

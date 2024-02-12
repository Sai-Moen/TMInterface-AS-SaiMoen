namespace smnu
{
    /**
    * A number that can theoretically occupy infinite memory in order to represent any integer.
    * Implementation: 2's complement, array<uint>.
    */
    shared class BigInteger : Stringifiable
    {
        const BigInteger@ ZERO { get const { return BigInteger(); } }
        private const uint WIDTH { get const { return 0x20; } }

        BigInteger() { }

        BigInteger(const bool b)
        {
            Resize(1);
            this[0] = b ? 1 : 0;
        }

        BigInteger(const uint b)
        {
            Resize(1);
            this[0] = b;
        }

        BigInteger(const uint64 b)
        {
            Resize(2);
            this[0] = b;
            this[1] = b >> 32;
        }

        BigInteger(const int b)
        {
            Resize(1);
            this[0] = b;
        }

        BigInteger(const int64 b)
        {
            Resize(2);
            this[0] = b;
            this[1] = b >> 32;
        }

        protected array<uint> integerArray;

        protected uint get_opIndex(const uint index) const property
        {
            return integerArray[index];
        }

        protected void set_opIndex(const uint index, const uint value) property
        {
            integerArray[index] = value;
        }

        protected uint Length { get const { return integerArray.Length; } }
        protected uint Size { get const { return Length * WIDTH; } }

        protected uint IdealLength() const
        {
            uint i = Length;
            do if (i == 0) break;
            while (this[--i] == 0);
            return i + 1;
        }

        protected void Resize(const uint length)
        {
            integerArray.Resize(length);
        }

        protected BigInteger@ Copy(const uint min = 0)
        {
            const uint len = IdealLength();
            Resize(len);

            BigInteger copy;
            copy.integerArray = integerArray;
            copy.Resize(min > len ? min : len);
            return copy;
        }

        BigInteger@ opNeg()
        {
            return ~this + 1;
        }

        BigInteger@ opCom()
        {
            BigInteger@ const copy = Copy();
            for (uint i = 0; i < copy.Length; i++)
            {
                copy[i] = ~copy[i];
            }
            return copy;
        }

        bool opEquals(const BigInteger@ const other) const
        {
            const uint size = IdealLength();
            if (size != other.IdealLength()) return false;
            
            const uint index = size - 1;
            return this[index] == other[index];
        }

        int opCmp(const BigInteger@ const other) const
        {
            const uint ourLen = IdealLength();
            const uint theirLen = other.IdealLength();

            int cmp;
            if (ourLen < theirLen)      cmp = -1;
            else if (ourLen > theirLen) cmp = 1;
            else
            {
                const uint ours = this[ourLen - 1];
                const uint others = other[theirLen - 1];
                if (ours < others)      cmp = -1;
                else if (ours > others) cmp = 1;
                else                    cmp = 0;
            }
            return cmp;
        }

        BigInteger@ opAdd(BigInteger@ const other)
        {
            BigInteger@ const copy = Copy(other.Length);
            BigInteger@ const otherCopy = other.Copy(copy.Length);

            bool carry = false;
            for (uint i = 0; i < copy.Length; i++)
            {
                const uint value = otherCopy[i] + (carry ? 1 : 0);
                copy[i] = copy[i] + value;
                carry = value == 0 || copy[i] < value;
            }
            
            if (carry)
            {
                copy.Resize(copy.Length + 1);
                copy[copy.Length - 1] = 1;
            }
            return copy;
        }

        BigInteger@ opSub(BigInteger@ const other)
        {
            return this + -other;
        }

        BigInteger@ opMul(BigInteger@ const other)
        {
            // https://en.wikipedia.org/wiki/Booth%27s_multiplication_algorithm

            const uint x = Size;
            const uint y = other.Size;
            const uint size = x + y + 1;
            const uint len = size / WIDTH + 1;

            return null; // FIXME
        }

        BigInteger@ opShl(BigInteger@ const other)
        {
            return null;
        }

        BigInteger@ opShr(BigInteger@ const other)
        {
            return null;
        }

        string Binary() const
        {
            string builder;
            for (uint i = 0; i < Length; i++)
            {
                const uint value = this[i];
                for (uint bit = 0; bit < WIDTH; bit++)
                {
                    builder += value & 1 << bit == 0 ? "0" : "1";
                }
            }
            return builder;
        }

        string opConv() const override
        {
            // if I have time and a lack of sanity, then I might implement a proper decimal one
            return Binary();
        }
    }
}

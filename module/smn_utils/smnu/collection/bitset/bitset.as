namespace smnu
{
    /**
    * An interface shared by all {BitSet}s.
    * Goal: provide easier ways to interact with an array<bool>-like data structure.
    * Also, looking through as_array.h from the angelscript repo, it seemingly doesn't do the weird C++ std::vector<bool> stuff.
    * Meaning that it will store bools as bytes instead of bits, so it'll be more space efficient to use this instead.
    */
    shared interface BitSet : Stringifiable
    {
        /**
        * The amount of bits that are currently in use by this {BitSet}.
        */
        uint Size { get const; }

        /**
        * Creates a (deep) copy of this {BitSet}.
        * @ret: deep copy of this {BitSet}
        */
        BitSet@ Copy() const;

        /**
        * Returns if the other {BitSet} equals this {BitSet}.
        * @param other: the other object
        * @ret: whether this equals other
        */
        bool opEquals(const BitSet@ &in other) const;


        /**
        * Gets the state of the bit at |index|.
        * @param index: the index of the bit
        * @ret: true if 1, false if 0
        */
        bool Get(const uint index) const;

        /**
        * Sets the state of the bit at |index|.
        * @param index: the index of the bit
        * @param value: the new state of the bit
        */
        void Set(const uint index, const bool value);

        /**
        * Resets all bits (& 0, in-place).
        */
        void Reset();

        /**
        * Resets the bit at |index|.
        * @param index: the index of the bit
        */
        void Reset(const uint index);


        /**
        * Flips all bits (^, in-place).
        */
        void Flip();

        /**
        * Flips the bit at |index|.
        * @param index: the index of the bit
        */
        void Flip(const uint index);

        /**
        * Creates a bitwise-complemented version of this {BitSet}.
        * @ret: bitwise-complement copy of this {BitSet}
        */
        BitSet@ opCom() const;


        /**
        * Performs a bitwise-and on the two operands, and returns the result.
        * @param right: the right operand
        * @ret: bitwise-and of the operands, null if incompatible concrete types or sizes
        */
        BitSet@ opAnd(const BitSet@ const right) const;

        /**
        * Performs a bitwise-or on the two operands, and returns the result.
        * @param right: the right operand
        * @ret: bitwise-or of the operands, null if incompatible concrete types or sizes
        */
        BitSet@ opOr(const BitSet@ const right) const;

        /**
        * Performs a bitwise-xor on the two operands, and returns the result.
        * @param right: the right operand
        * @ret: bitwise-xor of the operands, null if incompatible concrete types or sizes
        */
        BitSet@ opXor(const BitSet@ const right) const;
    }
}

namespace smnu::bitsets
{
    /**
    * Creates the appropriate {BitSet}, based on |size|.
    * @param size: the number of bits needed
    * @ret: a {BitSet} that has a number of bits at least as large as |size|
    */
    shared BitSet@ AutoBitSet(const uint size)
    {
        BitSet@ bits;
        if (size <= 8)       @bits = BitSet8();
        else if (size <= 16) @bits = BitSet16();
        else if (size <= 32) @bits = BitSet32();
        else if (size <= 64) @bits = BitSet64();
        else                 @bits = DynamicBitSet(size);
        return bits;
    }
}

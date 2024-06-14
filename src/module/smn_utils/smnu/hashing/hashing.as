namespace smnu
{
    /**
    * Generates a pseudo-random {uint}. Not cryptographically safe.
    * @ret: pseudo-random number
    */
    shared uint RandomSeed()
    {
        uint64 seed = Time::Now;
        const uint shift = Math::Rand(0, 31);
        seed <<= shift;
        seed >>= shift;
        seed ^= Math::Rand(0, 1 << 15);
        return uint(seed);
    }
}

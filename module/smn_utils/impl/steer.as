namespace smnu::steer
{
    // Amount of possible steering values (131073)
    shared const int VALUES_AMOUNT()
    {
        return 0x20001;
    }

    // Full-steer magnitude (65536)
    shared const int FULL()
    {
        return 0x10000;
    }

    // Half-steer magnitude (32768)
    shared const int HALF()
    {
        return FULL() >>> 1;
    }

    // Minimum possible steering value (-65536)
    shared const int MIN()
    {
        return -FULL();
    }

    // Maximum possible steering value (65536)
    shared const int MAX()
    {
        return FULL();
    }

    // Convert from float [-1, 1] to int [-65536, 65536]
    shared int FromSmallFloat(const float small)
    {
        return int(small * FULL());
    }

    // Clamp int to [-65536, 65536]
    shared int Clamp(const int steer)
    {
        return Math::Clamp(steer, MIN(), MAX());
    }
}

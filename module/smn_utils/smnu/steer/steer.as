namespace smnu::steer
{
    typedef int steeringValue;

    /**
    * Amount of possible steering values (131073).
    */
    shared const steeringValue VALUES_AMOUNT()
    {
        return 0x20001;
    }

    /**
    * Full-steer magnitude (65536).
    */
    shared const steeringValue FULL()
    {
        return 0x10000;
    }

    /**
    * Half-steer magnitude (32768).
    */
    shared const steeringValue HALF()
    {
        return FULL() >>> 1;
    }

    /**
    * Minimum possible steering value (-65536).
    */
    shared const steeringValue MIN()
    {
        return -FULL();
    }

    /**
    * Maximum possible steering value (65536).
    */
    shared const steeringValue MAX()
    {
        return FULL();
    }

    /**
    * Convert from float [-1, 1] to int [-65536, 65536].
    */
    shared steeringValue FromSmallFloat(const float small)
    {
        return int(small * FULL());
    }

    /**
    * Clamp int to [-65536, 65536].
    */
    shared steeringValue Clamp(const int steer)
    {
        return Math::Clamp(steer, MIN(), MAX());
    }
}

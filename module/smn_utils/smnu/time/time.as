namespace smnu::time
{   
    typedef int ms;

    /**
    * Gets the amount of milliseconds per in-game tick.
    * @ret: ms per tick
    */
    shared const ms TICK()
    {
        return 10;
    }

    /**
    * Gets 2 times the milliseconds per tick.
    * @ret: ms per 2 ticks
    */
    shared const ms TICK2()
    {
        return TICK() << 1;
    }

    /**
    * Gets the time difference in amount of ticks between start and end.
    * @param start: start of the time range
    * @param end: end of the time range
    * @ret: time difference in tick amount
    */
    shared uint GetTickDiff(const ms start, const ms end)
    {
        return (end - start) / TICK();
    }
}

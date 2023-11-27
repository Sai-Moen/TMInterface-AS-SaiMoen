namespace smnu::time
{   
    typedef int ms;

    shared const ms TICK()
    {
        return 10;
    }

    shared const ms TICK2()
    {
        return TICK() << 1;
    }

    // Gets the time difference in amount of ticks between start and end
    // param start: start of the time range
    // param end: end of the time range
    // returns: time difference in tick amount
    shared uint GetTickDiff(const ms start, const ms end)
    {
        return (end - start) / TICK();
    }
}

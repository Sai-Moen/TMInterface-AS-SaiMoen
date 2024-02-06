namespace smnu::Time
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

    /**
    * Tries to parse the given time, outputs |value|.
    * @param raceTime: Race Time as a {string}
    * @param &out value: Race Time as an {int}
    * @ret: whether |value| contains a valid time
    */
    shared bool TryParse(const string &in raceTime, int &out value)
    {
        value = Time::Parse(raceTime);
        return value != -1;
    }
}

// smn_utils - v2.1.1a

/*

Time
- milliseconds alias
- constants
- functions

*/


typedef int32 ms;

const ms TICK = 10;

ms TickToMs(const int tick)
{
    return tick * TICK;
}

int MsToTick(const ms time)
{
    return time / TICK;
}

bool ParseTime(const string &in raceTime, int &out value)
{
    value = Time::Parse(raceTime);
    return value != -1;
}

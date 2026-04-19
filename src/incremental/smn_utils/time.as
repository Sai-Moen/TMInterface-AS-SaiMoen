/*

smn_utils | Time | v3.0.0

Features:
- Milliseconds aliases
- Constants
- Functions

*/


typedef uint32 ums; // Input Event Buffer timestamps
typedef int32 ms; // TMInterface-adjusted time

const ms TICK = 10;

ms TickToMs(const int tick)
{
    return tick * 10;
}

int MsToTick(const ms time)
{
    return time / 10;
}

bool ParseTime(const string &in raceTime, int &out value)
{
    value = Time::Parse(raceTime);
    return value != -1;
}

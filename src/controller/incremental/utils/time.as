const ms TICK = 10;

namespace utils
{


ms TickToMs(const int tick)
{
    return tick * TICK;
}

int MsToTick(const ms time)
{
    return time / TICK;
}


} // namespace utils

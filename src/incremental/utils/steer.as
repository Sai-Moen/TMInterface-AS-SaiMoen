namespace STEER
{
    const int FULL = 0x10000;
    const int HALF = FULL >> 1;
    const int MIN  = -FULL;
    const int MAX  = FULL;
}

namespace utils
{


int ToSteer(const float small)
{
    return int(small * STEER::FULL);
}

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER::MIN, STEER::MAX);
}

enum Signum
{
    Negative = -1,
    Zero = 0,
    Positive = 1,
}

Signum Sign(const int num)
{
    return Signum((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

Signum Sign(const float num)
{
    return Signum((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

int RoundAway(const float magnitude, const float direction)
{
    return RoundAway(magnitude, Sign(direction));
}

int RoundAway(const float magnitude, const Signum direction)
{
    switch (direction)
    {
    case Signum::Negative: return int(Math::Floor(magnitude));
    case Signum::Zero:     return int(magnitude);
    case Signum::Positive: return int(Math::Ceil(magnitude));
    default:               return 0; // unreachable
    }
}


} // namespace utils

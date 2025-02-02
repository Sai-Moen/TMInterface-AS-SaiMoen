// smn_utils - v2.1.0a

/*

Steering
- Constants
- Functions

*/


const int STEER_FULL = 0x10000;
const int STEER_MIN  = -STEER_FULL;
const int STEER_MAX  =  STEER_FULL;

const int STEER_HALF = STEER_FULL / 2;

int ToSteer(const float small)
{
    return int(small * STEER_FULL);
}

int ClampSteer(const int steer)
{
    return Math::Clamp(steer, STEER_MIN, STEER_MAX);
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

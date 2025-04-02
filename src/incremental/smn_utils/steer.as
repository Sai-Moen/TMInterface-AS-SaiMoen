// smn_utils - v2.1.1a

/*

Steering
- constants
- functions

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

enum Sign
{
    Negative = -1,
    Zero = 0,
    Positive = 1,
}

Sign GetSign(const int num)
{
    return Sign((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

Sign GetSign(const float num)
{
    return Sign((num > 0 ? 1 : 0) - (num < 0 ? 1 : 0));
}

int RoundAway(const float magnitude, const float direction)
{
    return RoundAway(magnitude, GetSign(direction));
}

int RoundAway(const float magnitude, const Sign direction)
{
    switch (direction)
    {
    case Sign::Negative: return int(Math::Floor(magnitude));
    case Sign::Zero:     return int(magnitude);
    case Sign::Positive: return int(Math::Ceil(magnitude));
    default:             return 0; // unreachable
    }
}

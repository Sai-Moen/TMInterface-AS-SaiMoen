// common/utils

bool IsOtherController()
{
    return ID != GetVariableString("controller");
}

bool BufferGetBinary(
    TM::InputEventBuffer@ const buffer,
    const int time,
    const InputType type,
    const bool current)
{
    const auto@ const indices = buffer.Find(time, type);
    if (indices.IsEmpty()) return current;

    return buffer[indices[indices.Length - 1]].Value.Binary;
}

namespace STEER
{
    const int FULL = 0x10000;
}

int ToSteer(const float small)
{
    return int(small * STEER::FULL);
}

int ToSteerFloor(const float small)
{
    return int(Math::Floor(small * STEER::FULL));
}

int ToSteerCeil(const float small)
{
    return int(Math::Ceil(small * STEER::FULL));
}

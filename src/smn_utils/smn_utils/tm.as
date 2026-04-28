/*

smn_utils | TM | v3.0.0

Features:
- TM::InputEventBuffer (IEB) helpers

Notes:
By convention, 'time' means TMInterface-adjusted time, and 'timestamp' is the InputEvent time, i.e.
ms time = timestamp - 100010,
ums timestamp = time + 100010.

*/


const ums IEB_TIME_OFFSET = 100010;

// Binary search for time.
// Returns -1 if not found.
int BufferFindTime(const TM::InputEventBuffer@ buffer, const ms time, const int direction)
{
    return BufferFindTimestamp(buffer, time + IEB_TIME_OFFSET, direction);
}

// Binary search for timestamp, then go left or right depending on direction (or just return), to find one end of a time region.
// Returns -1 if not found.
int BufferFindTimestamp(const TM::InputEventBuffer@ buffer, const ums timestamp, const int direction)
{
    const uint index = BufferSearchTimestamp(buffer, timestamp, direction);
    if (index >= buffer.Length || buffer[index].Time != timestamp)
        return -1;

    return index;
}

// Binary search for time.
// Returns index (<= buffer.Length) of where an input event would have been added (given the time and direction).
uint BufferSearchTime(const TM::InputEventBuffer@ buffer, const ms time, const int direction)
{
    return BufferSearchTimestamp(buffer, time + IEB_TIME_OFFSET, direction);
}

// Binary search for timestamp, then go left or right depending on direction (or just return), to find one end of a time region.
// Returns index (<= buffer.Length) of where an input event would have been added (given the timestamp and direction).
uint BufferSearchTimestamp(const TM::InputEventBuffer@ buffer, const ums timestamp, const int direction)
{
    const uint length = buffer.Length;
    if (length == 0)
        return 0;

    uint index = 0;
    for (uint lower = 0, upper = length;;)
    {
        const uint diff = upper - lower;
        if (diff < 2)
        {
            index = lower;
            break;
        }

        const uint mid = lower + diff / 2;
        const ums midTimestamp = buffer[mid].Time;
        if (midTimestamp == timestamp)
        {
            index = mid;
            break;
        }

        // lol
        (midTimestamp < timestamp ? lower : upper) = mid;
    }

    const ums indexTimestamp = buffer[index].Time;
    if (indexTimestamp == timestamp)
    {
        if (direction != 0)
        {
            for (;;)
            {
                const uint next = index + direction;
                if (next >= length || buffer[next].Time != timestamp)
                    break;

                index = next;
            }
        }
    }
    else if (indexTimestamp < timestamp)
    {
        ++index;
    }

    return index;
}

// We assume here that uint suffices, based on the largest InputType member being smaller than the amount of bits in a uint.
// Otherwise, make a bit array version.
uint BufferInputTypesToEventIndexBitmask(const TM::InputEventBuffer@ buffer, const array<InputType>@ inputTypes)
{
    uint mask = 0;

    const auto eventIndices = buffer.EventIndices;
    const uint length = inputTypes.Length;
    for (uint i = 0; i < length; ++i)
    {
        int eventIndex = -1;

        switch (inputTypes[i])
        {
        case InputType::Down:       eventIndex = eventIndices.BrakeId;      break;
        case InputType::Up:         eventIndex = eventIndices.AccelerateId; break;
        case InputType::Left:       eventIndex = eventIndices.SteerLeftId;  break;
        case InputType::Right:      eventIndex = eventIndices.SteerRightId; break;
        case InputType::Steer:      eventIndex = eventIndices.SteerId;      break;
        case InputType::Gas:        eventIndex = eventIndices.GasId;        break;
        case InputType::Respawn:    eventIndex = eventIndices.RespawnId;    break;
        //   InputType::GiveUp: I assume this one does not show up in the IEB...
        case InputType::Horn:       eventIndex = eventIndices.HornId;       break;
        case InputType::FakeFinish: eventIndex = eventIndices.FinishLineId; break;
        default:
            PanicLog("Undefined InputType in BufferInputTypesToEventIndexBitmask");
        break;
        }

        mask |= 1 << eventIndex;
    }

    return mask;
}

// Returns: non-null handle to an array of indices of input events in the timerange of a type from inputTypes.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const array<InputType>@ inputTypes)
{
    if (timeTo < timeFrom)
        return {};

    const uint mask = BufferInputTypesToEventIndexBitmask(buffer, inputTypes);
    return BufferFindInTimerange(buffer, timeFrom, timeTo, mask);
}

// Returns: non-null handle to an array of indices of input events in the timerange matching the mask.
array<uint>@ BufferFindInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const uint mask)
{
    if (timeTo < timeFrom)
        return {};

    const ums timestampFrom = timeFrom + IEB_TIME_OFFSET;
    const ums timestampTo   = timeTo   + IEB_TIME_OFFSET;

    const uint length = buffer.Length;
    array<uint> indices((timeTo - timeFrom + 1) * 10);
    const uint index = BufferSearchTimestamp(buffer, timestampFrom, -1);
    for (uint i = index; i < length; ++i)
    {
        const auto inputEvent = buffer[i];
        if (inputEvent.Time > timestampTo)
            break;

        const uint masked = (1 << inputEvent.Value.EventIndex) & mask;
        if (masked != 0)
            indices.Add(i);
    }
    return indices;
}

// Effectively sets 'buffer.Length' to 'index'.
// If index > buffer.Length, it will throw an exception (it will not try to add dummy input events).
void BufferKeepUntil(TM::InputEventBuffer@ buffer, const uint index)
{
    const uint length = buffer.Length;
    // NOTE: this if-statement is only needed due to an edge case in TMInterface.
    // != is chosen so we do not hide correctness issues in the caller's code.
    if (length != index)
        buffer.RemoveAt(index, length - index);
}

void BufferRemoveInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const array<InputType>@ inputTypes)
{
    if (timeTo < timeFrom)
        return;

    const uint mask = BufferInputTypesToEventIndexBitmask(buffer, inputTypes);
    const array<uint>@ indices = BufferFindInTimerange(buffer, timeFrom, timeTo, mask);
    BufferRemoveIndices(buffer, indices);
}

void BufferRemoveInTimerange(
    TM::InputEventBuffer@ buffer, const ms timeFrom, const ms timeTo, const uint mask)
{
    if (timeTo < timeFrom)
        return;

    const array<uint>@ indices = BufferFindInTimerange(buffer, timeFrom, timeTo, mask);
    BufferRemoveIndices(buffer, indices);
}

// NOTE: indices must be sorted in ascending order (getting indices from a linear search like Find, does this automatically).
void BufferRemoveIndices(TM::InputEventBuffer@ buffer, const array<uint>@ indices, const uint indicesBase = 0)
{
    const uint indicesLen = indices.Length;
    if (indicesBase >= indicesLen)
        return;

    uint indicesIndex = indicesBase;
    uint index = indices[indicesIndex++];
    const uint bufferLen = buffer.Length;
    for (uint i = index + 1; i < bufferLen; ++i)
    {
        if (indicesIndex < indicesLen && i == indices[indicesIndex])
            ++indicesIndex;
        else
            buffer[index++] = buffer[i];
    }
    BufferKeepUntil(buffer, index);
}

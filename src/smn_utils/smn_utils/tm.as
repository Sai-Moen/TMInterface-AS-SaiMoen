/*

smn_utils | TM | v3.0.0

Features:
- TM::InputEventBuffer (IEB) helpers

Notes:
By convention, 'time' means TMInterface-adjusted time, and 'timestamp' is the InputEvent time, i.e.
ms time = timestamp - 100010,
ums timestamp = time + 100010.

*/


// Binary search for time, adjusts to the IEB difference between time and timestamp.
uint BufferSearchForTime(const TM::InputEventBuffer@ buffer, const ms time, const int direction)
{
    return BufferSearchForTimestamp(buffer, time + 100010, direction);
}

// Binary search for timestamp, then go left or right depending on direction (or just return), to find one end of a time region.
// Returns ~0 (UINT_MAX) if not found.
uint BufferSearchForTimestamp(const TM::InputEventBuffer@ buffer, const ums timestamp, const int direction)
{
    const uint length = buffer.Length;
    if (length == 0)
        return ~0;

    uint lower = 0;
    for (uint upper = length;;)
    {
        const uint diff = upper - lower;
        if (diff < 2)
            break;

        const uint mid = lower + diff / 2;
        const ums midTimestamp = buffer[mid].Time;
        if (midTimestamp <= timestamp)
        {
            lower = mid;
            if (midTimestamp == timestamp)
                break;
        }
        else
        {
            upper = mid;
        }
    }

    if (buffer[lower].Time != timestamp)
        return ~0;

    if (direction != 0)
    {
        for (;;)
        {
            const uint next = lower + direction;
            if (next >= length || buffer[next].Time != timestamp)
                break;

            lower = next;
        }
    }
    return lower;
}

// We assume here that uint suffices, based on the largest InputType member being smaller than the amount of bits in a uint.
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

    const ums timestampFrom = timeFrom + 100010;
    const ums timestampTo   = timeTo   + 100010;

    const uint len = buffer.Length;
    array<uint> indices(len / 8);
    const uint index = BufferSearchForTimestamp(buffer, timestampFrom, -1);
    for (uint i = index; i < len; ++i)
    {
        const auto@ const inputEvent = buffer[i];
        if (inputEvent.Time > timestampTo)
            break;

        const uint masked = (1 << inputEvent.EventIndex) & mask;
        if (masked != 0)
            indices.Add(i);
    }
    return indices;
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

// NOTE: indices must be sorted in ascending order (getting indices from a linear search i.e. Find does this automatically).
void BufferRemoveIndices(TM::InputEventBuffer@ buffer, const array<uint>@ indices, const uint indicesBase = 0)
{
    const uint indicesLen = indices.Length;
    if (indicesLen <= indicesBase)
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
    buffer.RemoveAt(index, indicesLen - indicesBase);
}

array<TM::InputEvent>@ BufferCopyInputEvents(const TM::InputEventBuffer@ buffer)
{
    const uint len = buffer.Length;
    array<TM::InputEvent> events(len);
    for (uint i = 0; i < len; ++i)
        events[i] = buffer[i];
    return events;
}

void BufferReplaceInputEvents(TM::InputEventBuffer@ buffer, const array<TM::InputEvent>@ events)
{
    const uint bufferLen = buffer.Length;
    const uint eventsLen = events.Length;
    if (bufferLen > eventsLen)
    {
        uint i;
        for (i = 0; i < eventsLen; ++i)
            buffer[i] = events[i];

        buffer.RemoveAt(i, bufferLen - eventsLen);
    }
    else
    {
        uint i;
        for (i = 0; i < bufferLen; ++i)
            buffer[i] = events[i];

        while (i < eventsLen)
            buffer.Add(events[i++]);
    }
}

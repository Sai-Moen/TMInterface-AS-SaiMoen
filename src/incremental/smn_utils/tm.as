/*

smn_utils | TM | v3.0.0

Features:
- TM::InputEventBuffer helpers

*/


array<TM::InputEvent>@ BufferCopyInputEvents(const TM::InputEventBuffer@ buffer)
{
    const uint len = buffer.Length;
    array<TM::InputEvent> events(len);
    for (uint i = 0; i < len; i++)
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
        for (i = 0; i < eventsLen; i++)
            buffer[i] = events[i];

        buffer.RemoveAt(i, bufferLen - eventsLen);
    }
    else
    {
        uint i;
        for (i = 0; i < bufferLen; i++)
            buffer[i] = events[i];

        while (i < eventsLen)
            buffer.Add(events[i++]);
    }
}

void BufferRemoveInTimerange(
    TM::InputEventBuffer@ buffer,
    const ms timeFrom, const ms timeTo,
    const array<InputType>@ types)
{
    if (timeFrom > timeTo)
        return;

    array<array<uint>@> indexArrayArray;
    uint capacity = 0;
    const uint typesLen = types.Length;
    for (ms t = timeFrom; t <= timeTo; t += TICK)
    {
        for (uint i = 0; i < typesLen; i++)
        {
            auto@ const indexArray = buffer.Find(t, types[i]);
            capacity += indexArray.Length;
            indexArrayArray.Add(indexArray);
        }
    }

    array<uint> indices(capacity);
    uint index = 0;
    for (uint i = 0; i < indexArrayArray.Length; i++)
    {
        const auto@ const indexArray = indexArrayArray[i];
        for (uint j = 0; j < indexArray.Length; j++)
            indices[index++] = indexArray[j];
    }

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

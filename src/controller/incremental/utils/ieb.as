// Input Event Buffer

namespace utils
{


void BufferRemoveInTimerange(
    TM::InputEventBuffer@ const buffer,
    const ms timeFrom, const ms timeTo,
    const array<InputType> &in types) // expecting it to be a small array
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

void BufferRemoveIndices(TM::InputEventBuffer@ const buffer, const array<uint>@ const indices)
{
    if (indices.IsEmpty())
        return;

    uint contiguous = 1;
    const uint len = indices.Length;
    uint old = indices[len - 1];
    for (int i = len - 2; i != -1; i--)
    {
        const uint new = indices[i];
        if (new == old - 1)
        {
            contiguous++;
        }
        else
        {
            buffer.RemoveAt(old, contiguous);
            contiguous = 1;
        }
        old = new;
    }
    buffer.RemoveAt(old, contiguous);
}


} // namespace utils

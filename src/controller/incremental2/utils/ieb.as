// Input Event Buffer

namespace utils
{


void BufferRemoveInTimerange(
    TM::InputEventBuffer@ const buffer,
    const ms start, const ms end,
    const InputType type = InputType::None)
{
    if (start > end)
        return;

    array<array<uint>@> indexArrayArray;
    uint capacity = 0;
    for (ms t = start; t <= end; t += TICK)
    {
        auto@ const indexArray = buffer.Find(t, type);
        capacity += indexArray.Length;
        indexArrayArray.Add(indexArray);
    }

    array<uint> indices(capacity);
    uint index = 0;
    for (uint i = 0; i < indexArrayArray.Length; i++)
    {
        const auto@ const indexArray = indexArrayArray[i];
        for (uint j = 0; j < indexArray.Length; j++)
            indices[index++] = indexArray[j];
    }

    RemoveIndices(buffer, indices);
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

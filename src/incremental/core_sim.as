namespace Core::Sim
{


void SetInput(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    const uint relativeTick = MsToTick(time - tInput);
    do
    {
        const uint requiredMod = relativeTick + 1;
        if (cacheMod >= requiredMod)
            break;

        const uint mod = cacheMod;
        cacheMod = requiredMod;
        cache.Resize(cacheMod * INPUT_TYPE_COUNT);

        const uint offset = cacheOffset;
        cacheOffset = 0;
        if (mod == 0)
            break;

        // Overlapping on the left, copy right-to-left.
        for (uint i = INPUT_TYPE_COUNT - 1; i != 0; --i)
        {
            const uint old = i * mod;
            const uint new = i * cacheMod;
            for (uint j = 0; j < mod; ++j)
            {
                const uint cacheIndex = old + (offset + j) % mod;
                cache[new + j] = cache[cacheIndex];
                cache[cacheIndex] = 0;
            }
        }
    }
    while (false);

    auto@ const buffer = sim.InputEvents;

    const uint cacheIndex = type * cacheMod + (cacheOffset + relativeTick) % cacheMod;
    uint eventIndex = cache[cacheIndex];
    if (eventIndex == 0)
    {
        auto@ indices = buffer.Find(time, type);
        switch (indices.Length)
        {
        case 0:
            {
                if (tCleanup < time)
                    tCleanup = time;

                buffer.Add(time, type, value);
                @indices = buffer.Find(time, type);
                Assert(indices.Length == 1);
                const uint index = indices[0];

                const uint cacheLen = cache.Length;
                for (uint i = 0; i < cacheLen; i++)
                {
                    if (cache[i] > index)
                        ++cache[i];
                }
            }
        // fallthrough
        case 1:
            // We have exactly 1 input with the required time and type, let's cache and set that one.
        break;
        default:
            {
                BufferRemoveIndices(buffer, indices, 1);

                const uint indicesLen = indices.Length;
                if (indicesLen <= indicesBase)
                    break;

                const uint cacheLen = cache.Length;
                for (uint i = 0; i < cacheLen; i++)
                {
                    const uint cached = cache[i];
                    if (cached == 0)
                        continue;

                    uint shift = 0;
                    for (uint j = indicesBase; j < indicesLen; j++)
                    {
                        const uint index = indices[j];
                        AssertLog(index != cached, "Index to be removed cannot be in the cache!");
                        if (index > cached)
                            break;

                        ++shift;
                    }
                    cache[i] -= shift;
                }
            }
        break;
        }

        eventIndex = indices[0];
        cache[cacheIndex] = eventIndex;
    }

    buffer[eventIndex].Value.Analog = value;
}

bool HasInputs(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    return !sim.InputEvents.Find(time, type, value).IsEmpty();
}

void RemoveInputs(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    auto@ const buffer = sim.InputEvents;
    const uint len = buffer.Length;
    BufferRemoveIndices(buffer, buffer.Find(time, type, value));

    if (buffer.Length < len)
        cache.Clear();
}

void RemoveSteeringAhead(SimulationManager@ sim)
{
    auto@ const buffer = sim.InputEvents;
    const uint len = buffer.Length;
    BufferRemoveInTimerange(
        buffer, tInput, tCleanup,
        { InputType::Left, InputType::Right, InputType::Steer });

    if (buffer.Length < len)
        cache.Clear();
}


} // namespace Core::Sim

namespace Eval
{


// - General -
array<TM::InputEvent> initialEvents;

void Initialize(SimulationManager@ simManager)
{
    const auto@ const buffer = simManager.InputEvents;
    const uint len = buffer.Length;
    initialEvents.Resize(len);
    for (uint i = 0; i < len; i++)
        initialEvents[i] = buffer[i];

    const int temp = (Settings::varEvalBeginStop - Settings::varEvalBeginStart) / TICK + 1;
    const uint size = Math::Max(temp, 1);

    resultIndex = 0;
    resultTimes.Resize(size + 1);
    resultInputs.Resize(size);
    resultStates.Resize(size);

    uint t = Settings::varEvalBeginStop;
    for (uint i = 0; i < size; i++)
    {
        resultTimes[i] = t;
        t -= TICK;
    }
    resultTimes[size] = INVALID_RESULT_TIME;

    tInput = resultTimes[resultIndex];
    tTrail = tInput - TICK;
}

void InitializeInitTime()
{
    tInit = Settings::varEvalBeginStart - TickToMs(2);
}

void Advance()
{
    PopCaches();
    Bump();
}

void Finish(SimulationManager@ simManager)
{
    needToHandleCancel = false;
    onStep = OnStepState::None;
    simManager.ForceFinish();
}

void Reset()
{
    initialEvents.Clear();

    @initState = null;
    @trailingState = null;

    ClearInputCaches();

    resultTimes.Clear();
    resultInputs.Clear();
    resultStates.Clear();
}

// - Modes -
uint modeIndex;
array<string> modeNames;
array<IncMode@> modes;

bool supportsSaveStates;
bool supportsUnlockedTimerange;

funcdef void OnEvent();
OnEvent@ modeRenderSettings;

funcdef void OnSim(SimulationManager@);
OnSim@ modeOnBegin;
OnSim@ modeOnStep;
OnSim@ modeOnEnd;

bool IsUnlockedTimerange()
{
    return supportsUnlockedTimerange && Settings::varEvalBeginStart < Settings::varEvalBeginStop;
}

bool ShouldTryLoadingSaveState()
{
    return supportsSaveStates && Settings::varUseSaveState;
}

string GetCurrentModeName()
{
    return modeNames[modeIndex];
}

void OnModeIndex(const uint newIndex)
{
    modeIndex = newIndex;

    const uint len = modes.Length;
    if (modeIndex < len)
        ModeDispatch();
    else
        log("Mode Index somehow went out of bounds... (" + modeIndex + " >= " + len + ")", Severity::Warning);
}

void ModeDispatch()
{
    IncMode@ imode = modes[modeIndex];

    supportsSaveStates = imode.SupportsSaveStates;
    supportsUnlockedTimerange = imode.SupportsUnlockedTimerange;

    @modeRenderSettings = imode.RenderSettings;

    @modeOnBegin = imode.OnBegin;
    @modeOnStep = imode.OnStep;
    @modeOnEnd = imode.OnEnd;
}

// - Timestamps -
ms tInit;  // the timestamp required to ensure that we can run an entire timerange
ms tTrail; // the timestamp that the trailing state is saved on
ms tInput; // the timestamp currently being evaluated
ms tLimit; // the timestamp that triggers the end of the simulation when the input time exceeds it

SimulationState@ initState;
SimulationState@ trailingState;

void Bump()
{
    tTrail += TICK;
    tInput += TICK;
}

bool IsInitTime(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (time < tInit)
        return false;

    if (time == tInit)
    {
        @initState = simManager.SaveState();
        return true;
    }
    else
    {
        print("Got beyond Init time without going out of Init mode...", Severity::Error);
        Finish(simManager);
        return false;
    }
}

bool IsAtLeastInputTime(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (time == tTrail)
        @trailingState = simManager.SaveState();
    return time >= tInput;
}

// - Inputs -
const uint INVALID_CACHE = -1;

array<uint> cacheDown;
array<uint> cacheUp;
array<uint> cacheSteer;

void SetInput(SimulationManager@ simManager, const uint index, const InputType type, const int value)
{
    array<uint>@ cache;
    switch (type)
    {
    case InputType::Down:
        @cache = cacheDown;
        break;
    case InputType::Up:
        @cache = cacheUp;
        break;
    case InputType::Steer:
        @cache = cacheSteer;
        break;
    default:
        print("Unsupported input was attempted to be set...", Severity::Warning);
        return;
    }

    const uint len = cache.Length;
    if (index >= len)
    {
        cache.Resize(index + 1);
        for (uint i = len; i <= index; i++)
            cache[i] = INVALID_CACHE;
    }

    auto@ const buffer = simManager.InputEvents;

    uint eventIndex = cache[index];
    if (eventIndex == INVALID_CACHE)
    {
        const ms time = tInput + utils::TickToMs(index);
        auto@ indices = buffer.Find(time, type);
        switch (indices.Length)
        {
        case 0:
            buffer.Add(time, type, value);
            @indices = buffer.Find(time, type);
            ShiftInputCaches(indices, 1);
        case 1:
            eventIndex = indices[0];
            break;
        default:
            eventIndex = indices[0];
            indices.RemoveAt(0);
            utils::BufferRemoveIndices(buffer, indices);
            ShiftInputCaches(indices, -1);
            break;
        }

        cache[index] = eventIndex;
    }

    buffer[eventIndex].Value.Analog = value;
}

void ShiftInputCaches(const array<uint>@ const indices, const int shift)
{
    ShiftInputCache(cacheDown, indices, shift);
    ShiftInputCache(cacheUp, indices, shift);
    ShiftInputCache(cacheSteer, indices, shift);
}

void ShiftInputCache(array<uint>@ const cache, const array<uint>@ const indices, const int shift)
{
    const uint cacheLen = cache.Length;
    const uint indicesLen = indices.Length;
    for (uint i = 0; i < cacheLen; i++)
    {
        uint cached = cache[i];
        for (uint j = 0; j < indicesLen; j++)
        {
            if (indices[j] > cached)
                break; // presumably indices are always in ascending order

            cached += shift;
        }
        cache[i] = cached;
    }
}

void PopCaches()
{
    PopCache(cacheDown);
    PopCache(cacheUp);
    PopCache(cacheSteer);
}

void PopCache(array<uint>@ const cache)
{
    const uint last = cache.Length - 1;
    for (uint i = 0; i < last; i++)
        cache[i] = cache[i + 1];
    cache[last] = INVALID_CACHE;
}

void ClearInputCaches()
{
    cacheDown.Clear();
    cacheUp.Clear();
    cacheSteer.Clear();
}

// - Results -
const ms INVALID_RESULT_TIME = -1;

uint resultIndex;
array<ms> resultTimes;
array<string> resultInputs;
array<SimulationState@> resultStates;

void SaveResult(SimulationManager@ simManager)
{
    resultInputs[resultIndex] = simManager.InputEvents.ToCommandsText();
    @resultStates[resultIndex] = simManager.SaveState();
}

void NextResult()
{
    tInput = resultTimes[++resultIndex];
    tTrail = tInput - TICK;
    return tInput != INVALID_RESULT_TIME;
}

void PrepareResult(SimulationManager@ simManager)
{
    auto@ const buffer = simManager.InputEvents;
    buffer.Clear();
    const uint len = initialEvents.Length;
    for (uint i = 0; i < len; i++)
        buffer.Add(initialEvents[i]);

    simManager.RewindToState(initState);
    modeOnBegin(simManager);
}

string GetBestInputs()
{
    uint bestIndex = 0;
    float bestSpeed = resultStates[bestIndex].Dyna.RefStateCurrent.LinearSpeed.LengthSquared();
    const uint len = resultStates.Length;
    for (uint i = 1; i < len; i++)
    {
        const float otherSpeed = resultStates[i].Dyna.RefStateCurrent.LinearSpeed.LengthSquared();
        if (bestSpeed < otherSpeed)
        {
            bestSpeed = otherSpeed;
            bestIndex = i;
        }
    }
    return resultInputs[bestIndex];
}


} // namespace Eval

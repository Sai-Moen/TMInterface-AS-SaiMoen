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
    
    const uint duration = simManager.EventsDuration;
    if (Settings::varEvalEnd == 0)
        tLimit = duration;
    else
        tLimit = Settings::varEvalEnd;
    tCleanup = duration;
}

void InitializeInitTime()
{
    tInit = Settings::varEvalBeginStart - utils::TickToMs(2);
}

void Advance()
{
    PopInputCaches();
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
    speed = NO_SPEED;

    ClearInputCaches();

    resultTimes.Clear();
    resultInputs.Clear();
    resultStates.Clear();
}

// - Modes -
const uint INVALID_MODE_INDEX = uint(-1);

uint modeIndex = INVALID_MODE_INDEX;
array<string> modeNames;
array<IncMode@> modes;

bool supportsUnlockedTimerange;

funcdef void OnEvent();
OnEvent@ modeRenderSettings;

funcdef void OnSim(SimulationManager@);
OnSim@ modeOnBegin;
OnSim@ modeOnStep;
OnSim@ modeOnEnd;

bool IsUnlockedTimerange()
{
    return
        supportsUnlockedTimerange &&
        !Settings::varLockTimerange &&
        Settings::varEvalBeginStart < Settings::varEvalBeginStop;
}

bool ShouldTryLoadingSaveState()
{
    return Settings::varUseSaveState;
}

string GetCurrentModeName()
{
    return modeNames[modeIndex];
}

void CheckMode()
{
    if (modeIndex != INVALID_MODE_INDEX)
        return;

    const uint index = modeNames.Find(GetVariableString(Settings::VAR_MODE));
    modeIndex = index < modeNames.Length ? index : 0;
    ModeDispatch();
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
    IncMode@ const imode = modes[modeIndex];
    SetVariable(Settings::VAR_MODE, GetCurrentModeName());

    supportsUnlockedTimerange = imode.SupportsUnlockedTimerange;

    @modeRenderSettings = OnEvent(imode.RenderSettings);

    @modeOnBegin = OnSim(imode.OnBegin);
    @modeOnStep = OnSim(imode.OnStep);
    @modeOnEnd = OnSim(imode.OnEnd);
}

// - Timestamps -
ms tInit;    // the timestamp required to ensure that we can run an entire timerange
ms tTrail;   // the timestamp that the trailing state is saved on
ms tInput;   // the timestamp currently being evaluated
ms tLimit;   // the timestamp that triggers the end of the simulation when the input time exceeds it
ms tCleanup; // the timestamp of the inputs with the highest indices

SimulationState@ initState;
SimulationState@ trailingState;

const vec3 NO_SPEED = vec3();
vec3 speed;

void Bump()
{
    tTrail += TICK;
    tInput += TICK;

    speed = NO_SPEED;
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
    else if (speed == NO_SPEED && time == tInput)
        speed = simManager.Dyna.RefStateCurrent.LinearSpeed;
    return time >= tInput;
}

// - Inputs -
const uint INVALID_CACHE = uint(-1);

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
        print("Unsupported InputType to cache mapping...", Severity::Warning);
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
            if (tCleanup < time)
                tCleanup = time;
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
        const uint cached = cache[i];
        if (cached == INVALID_CACHE)
            continue;

        int shiftAccumulator = 0;
        for (uint j = 0; j < indicesLen; j++)
        {
            // presumably indices are always in ascending order
            // everything after the cache doesn't matter
            if (indices[j] > cached)
                break;

            shiftAccumulator += shift;
        }
        cache[i] += shiftAccumulator;
    }
}

void PopInputCaches()
{
    PopInputCache(cacheDown);
    PopInputCache(cacheUp);
    PopInputCache(cacheSteer);
}

void PopInputCache(array<uint>@ const cache)
{
    if (cache.IsEmpty())
        return;

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
    auto@ const buffer = simManager.InputEvents;
    const auto@ const indices = buffer.Find(-1, InputType::FakeFinish);
    if (indices.Length == 1)
    {
        const uint index = indices[0];
        auto event = buffer[index];
        buffer.RemoveAt(index);
        event.Time = Eval::tInput + 100000; // 100010 - 10
        buffer.Add(event);
    }
    else
    {
        print("Unexpected amount of FakeFinish inputs...", Severity::Error);
    }

    resultInputs[resultIndex] = buffer.ToCommandsText();
    @resultStates[resultIndex] = simManager.SaveState();
}

bool NextResult()
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
    float bestSpeed = resultStates[bestIndex].Dyna.CurrentState.LinearSpeed.LengthSquared();
    const uint len = resultStates.Length;
    for (uint i = 1; i < len; i++)
    {
        SimulationState@ const other = resultStates[i];
        if (other is null)
            break;

        const float otherSpeed = other.Dyna.CurrentState.LinearSpeed.LengthSquared();
        if (bestSpeed < otherSpeed)
        {
            bestSpeed = otherSpeed;
            bestIndex = i;
        }
    }
    return resultInputs[bestIndex];
}


} // namespace Eval

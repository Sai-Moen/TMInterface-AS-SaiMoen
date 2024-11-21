namespace Eval
{


// - General
array<TM::InputEvent>@ initialEvents;

void Initialize(SimulationManager@ simManager)
{
    // a different system is used for run-mode
    @initialEvents = IsRunSimOnly ? null : utils::CopyInputEvents(simManager.InputEvents);

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

    // need this even w/ locked timerange to verify save state
    tInit = Settings::varEvalBeginStart - utils::TickToMs(2);

    ms duration;
    if (IsRunSimOnly)
        duration = runReplayTime;
    else
        duration = simManager.EventsDuration;

    if (Settings::varEvalEnd == 0)
        tLimit = duration;
    else
        tLimit = Settings::varEvalEnd;
    tCleanup = duration;
}

void Advance()
{
    PopInputCaches();
    Bump();
}

void Finish(SimulationManager@ simManager)
{
    needToHandleCancel = false;
    onStep = OnStepState::NONE;

    if (IsRunSimOnly)
        soState = SimOnlyState::END;
    else
        simManager.ForceFinish();
}

void Reset()
{
    @initialEvents = null;

    inputStatesList.Clear();

    @initState = null;
    @trailingState = null;
    speed = NO_SPEED;

    ClearInputCaches();

    resultIndex = 0;
    resultTimes.Clear();
    resultInputs.Clear();
    resultStates.Clear();
}

// - Modes
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

// - Timestamps
ms tInit;    // the timestamp required to ensure that we can run an entire timerange
ms tTrail;   // the timestamp that the trailing state is saved on
ms tInput;   // the timestamp currently being evaluated
ms tLimit;   // the timestamp that triggers the end of the simulation when the input time exceeds it
ms tCleanup; // the timestamp of the inputs with the highest indices

SimulationState@ initState;
SimulationState@ trailingState;

const vec3 NO_SPEED = vec3();
vec3 speed;

bool rewinding = false;

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

void RewindToInitState(SimulationManager@ simManager)
{
    simManager.RewindToState(initState);
    rewinding = true;
}

void RewindToTrailingState(SimulationManager@ simManager)
{
    simManager.RewindToState(trailingState);
    rewinding = true;
}

// - Run Mode

// mirrors the SceneVehicleCar.Input* properties
class InputStates
{
    int brake = -1;
    int gas   = -1;
    int steer = Math::INT_MIN;
}

const InputStates inputNeutral;

ms runReplayTime;
array<InputStates> inputStatesList;

void InitInputStates()
{
    runReplayTime = Settings::varReplayTime;
    inputStatesList.Resize(utils::MsToTick(runReplayTime));
}

void CollectInputStates(SimulationManager@ simManager)
{
    CollectInputStates(simManager, simManager.TickTime);
}

void CollectInputStates(SimulationManager@ simManager, const ms time)
{
    const uint index = utils::MsToTick(time) - 1;
    if (index >= inputStatesList.Length)
        return;

    const auto@ const svc = simManager.SceneVehicleCar;

    InputStates inputStates;
    inputStates.brake = int(svc.InputBrake);
    inputStates.gas   = int(svc.InputGas);
    inputStates.steer = utils::ToSteer(svc.InputSteer);
    inputStatesList[index] = inputStates;
}

void ApplyInputStates(SimulationManager@ simManager)
{
    ApplyInputStates(simManager, simManager.TickTime);
}

void ApplyInputStates(SimulationManager@ simManager, const ms time)
{
    if (!IsRunSimOnly)
        return;

    // defer rewinding = false;

    const uint index = utils::MsToTick(time);
    if (index >= inputStatesList.Length)
    {
        rewinding = false;
        return;
    }

    const auto@ const inputStates = inputStatesList[index];
    const InputState oldInputState = simManager.GetInputState();
    auto@ const buffer = simManager.InputEvents;

    {
        const InputType type = InputType::Down;
        const int value = inputStates.brake;
        if (value != inputNeutral.brake)
        {
            if (rewinding)
            {
                const uint oldLen = buffer.Length;
                simManager.SetInputState(type, value);
                const uint newLen = buffer.Length;
                if (oldLen == newLen && oldInputState.Down != simManager.GetInputState().Down)
                    buffer.Add(time, type, value);
            }
            else
            {
                simManager.SetInputState(type, value);
            }
        }
    }

    {
        const InputType type = InputType::Up;
        const int value = inputStates.gas;
        if (value != inputNeutral.gas)
        {
            if (rewinding)
            {
                const uint oldLen = buffer.Length;
                simManager.SetInputState(type, value);
                const uint newLen = buffer.Length;
                if (oldLen == newLen && oldInputState.Up != simManager.GetInputState().Up)
                    buffer.Add(time, type, value);
            }
            else
            {
                simManager.SetInputState(type, value);
            }
        }
    }

    {
        const InputType type = InputType::Steer;
        const int value = inputStates.steer;
        if (value != inputNeutral.steer)
        {
            if (rewinding)
            {
                const uint oldLen = buffer.Length;
                simManager.SetInputState(type, value);
                const uint newLen = buffer.Length;
                if (oldLen == newLen && oldInputState.Steer != simManager.GetInputState().Steer)
                    buffer.Add(time, type, value);
            }
            else
            {
                simManager.SetInputState(type, value);
            }
        }
    }

    rewinding = false;
}

void ResetInputStates()
{
    runReplayTime = 0;
    inputStatesList.Clear();
}

// - Inputs
const uint INVALID_CACHE = uint(-1);

array<uint> cacheDown;
array<uint> cacheUp;
array<uint> cacheSteer;

void SetInput(SimulationManager@ simManager, const ms time, const InputType type, const int value)
{
    const uint absoluteIndex = utils::MsToTick(time);
    if (IsRunSimOnly)
    {
        if (absoluteIndex >= inputStatesList.Length)
            inputStatesList.Resize(absoluteIndex + 1);

        InputStates@ const inputStates = inputStatesList[absoluteIndex];
        switch (type)
        {
        case InputType::Down:  inputStates.brake = value; break;
        case InputType::Up:    inputStates.gas   = value; break;
        case InputType::Steer: inputStates.steer = value; break;
        default:
            print("Unsupported InputType for run-mode", Severity::Error);
            // fallthrough
        }

        return;
    }

    array<uint>@ cache;
    switch (type)
    {
    case InputType::Down:  @cache = cacheDown;  break;
    case InputType::Up:    @cache = cacheUp;    break;
    case InputType::Steer: @cache = cacheSteer; break;
    default:
        print("Unsupported InputType to cache mapping...", Severity::Error);
        return;
    }

    const uint index = absoluteIndex - utils::MsToTick(tInput);
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
        auto@ indices = buffer.Find(time, type);
        switch (indices.Length)
        {
        case 0:
            if (tCleanup < time)
                tCleanup = time;
            buffer.Add(time, type, value);
            @indices = buffer.Find(time, type);
            ShiftInputCaches(indices, 1);
            // fallthrough
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

bool HasInputs(
    SimulationManager@ simManager,
    const ms time, const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    if (IsRunSimOnly)
    {
        const uint index = utils::MsToTick(time);
        if (index >= inputStatesList.Length)
            return false;

        const auto@ const inputStates = inputStatesList[index];
        switch (type)
        {
        case InputType::None:
            return
                HasInputValue(inputStates.brake, inputNeutral.brake, value) ||
                HasInputValue(inputStates.gas,   inputNeutral.gas,   value) ||
                HasInputValue(inputStates.steer, inputNeutral.steer, value);
        case InputType::Down:
            return HasInputValue(inputStates.brake, inputNeutral.brake, value);
        case InputType::Up:
            return HasInputValue(inputStates.gas,   inputNeutral.gas,   value);
        case InputType::Steer:
            return HasInputValue(inputStates.steer, inputNeutral.steer, value);
        default:
            print("Unsupported InputType in HasInputs", Severity::Error);
            return false;
        }
    }
    else
    {
        return !simManager.InputEvents.Find(time, type, value).IsEmpty();
    }
}

bool HasInputValue(const int inputValue, const int neutral, const int value)
{
    if (inputValue == neutral)
        return false;

    if (value == Math::INT_MAX)
        return true;

    return inputValue == value;
}

void RemoveInputs(
    SimulationManager@ simManager,
    const ms time, const InputType type = InputType::None, const int value = Math::INT_MAX)
{
    if (IsRunSimOnly)
    {
        const uint index = utils::MsToTick(time);
        if (index >= inputStatesList.Length)
            return;

        InputStates@ const inputStates = inputStatesList[index];
        switch (type)
        {
        case InputType::None:
            if (value == Math::INT_MAX)
            {
                inputStatesList[index] = inputNeutral;
            }
            else
            {
                if (inputStates.brake == value) inputStates.brake = inputNeutral.brake;
                if (inputStates.gas   == value) inputStates.gas   = inputNeutral.gas;
                if (inputStates.steer == value) inputStates.steer = inputNeutral.steer;
            }
            break;
        case InputType::Down:
            if (value == Math::INT_MAX || inputStates.brake == value)
                inputStates.brake = inputNeutral.brake;
            break;
        case InputType::Up:
            if (value == Math::INT_MAX || inputStates.gas == value)
                inputStates.gas = inputNeutral.gas;
            break;
        case InputType::Steer:
            if (value == Math::INT_MAX || inputStates.steer == value)
                inputStates.steer = inputNeutral.steer;
            break;
        }
    }
    else
    {
        auto@ const buffer = simManager.InputEvents;
        const uint len = buffer.Length;
        utils::BufferRemoveIndices(buffer, buffer.Find(time, type, value));

        if (buffer.Length < len)
            ClearInputCaches();
    }
}

void RemoveSteeringAhead(SimulationManager@ simManager)
{
    if (IsRunSimOnly)
    {
        const uint len = inputStatesList.Length;
        for (uint i = utils::MsToTick(tInput); i < len; i++)
            inputStatesList[i].steer = inputNeutral.steer;
    }
    else
    {
        auto@ const buffer = simManager.InputEvents;
        const uint len = buffer.Length;
        utils::BufferRemoveInTimerange(
            buffer, tInput, tCleanup,
            { InputType::Left, InputType::Right, InputType::Steer });

        if (buffer.Length < len)
            ClearInputCaches();
    }
}

void ShiftInputCaches(const array<uint>@ const indices, const int shift)
{
    ShiftInputCache(cacheDown,  indices, shift);
    ShiftInputCache(cacheUp,    indices, shift);
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

// - Results
const int MAGIC_NANDO_TIME_OFFSET = 100010;
const ms INVALID_RESULT_TIME = -1;

uint resultIndex;
array<ms> resultTimes;
array<string> resultInputs;
array<SimulationState@> resultStates;

void SaveResult(SimulationManager@ simManager)
{
    auto@ const buffer = simManager.InputEvents;
    const auto@ const indices = buffer.Find(-1, InputType::FakeFinish);
    switch (indices.Length)
    {
    case 1:
        {
            const uint index = indices[0];
            auto event = buffer[index];
            buffer.RemoveAt(index);
            event.Time = tInput + MAGIC_NANDO_TIME_OFFSET - 10;
            buffer.Add(event);
        }
    case 0:
        break;
    default:
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
    if (!IsRunSimOnly)
        utils::ReplaceInputEvents(simManager.InputEvents, initialEvents);
    RewindToInitState(simManager);
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

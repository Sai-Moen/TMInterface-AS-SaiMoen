namespace Core
{


// - General

array<TM::InputEvent>@ initialEvents;

void Initialize(SimulationManager@ sim)
{
    // A different system is used for run-mode.
    if (contextMode == ContextMode::Simulation)
        @initialEvents = BufferCopyInputEvents(sim.InputEvents);

    speed = NO_SPEED;

    int timerange = MsToTick(Settings::varEvalBeginStop - Settings::varEvalBeginStart) + 1;
    if (timerange < 1)
        timerange = 1;
    results.Resize(timerange);

    uint t = Settings::varEvalBeginStop;
    for (uint i = 0; i < timerange; i++)
    {
        results[i].time = t;
        t -= TICK;
    }

    resultIndex = 0;

    // Need this even w/ locked timerange to verify savestate.
    tInit = Settings::varEvalBeginStart - TickToMs(2);

    tTrail = -20;
    tInput = -10;

    ms duration;
    switch (contextMode)
    {
    case ContextMode::Simulation:
        duration = runReplayTime;
    break;
    case ContextMode::Run:
        duration = sim.EventsDuration;
    break;
    default:
        Panic("Undefined ContextMode in Initialize");
    break;
    }

    if (Settings::varEvalEnd == 0)
        tLimit = duration;
    else
        tLimit = Settings::varEvalEnd;
    tCleanup = duration;
}

void Reset()
{
    @initialEvents = null;
    @initState = null;
    @trailingState = null;
    cache.Clear();
    results.Clear();
}

void Finish(SimulationManager@ sim)
{
    handleCancel = false;
    onStep = OnStepState::NONE;
    if (contextMode == ContextMode::Run)
        soState = SimOnlyState::END;
}

void Advance()
{
    tTrail += TICK;
    tInput += TICK;

    speed = NO_SPEED;

    const uint cacheLen = cache.Length;
    if (cacheLen == 0)
        return;

    for (uint i = cacheOffset; i < cacheLen; i += cacheMod)
        cache[i] = 0;
    cacheOffset = (cacheOffset + 1) % cacheMod;
}


// - Modes

array<string> modeNames;
array<IncMode@> modes;
uint modeIndex;
IncMode@ mode;

bool IsUnlockedTimerange()
{
    return mode.supportsUnlockedTimerange &&
        !Settings::varLockTimerange &&
        Settings::varEvalBeginStart < Settings::varEvalBeginStop;
}

string GetCurrentModeName()
{
    return modeNames[modeIndex];
}

void OnModeIndex(const uint index)
{
    if (SetModeIndex(index))
        return;

    StringBuilder sb; sb
        .Append("Mode Index went out of bounds... (")
        .Append(index)
        .Append(" >= ")
        .Append(modes.Length)
        .Append(")");
    log(sb.ToString(), Severity::Warning);
}

void ResolveModeIndex()
{
    const uint index = GetCurrentModeIndex();
    if (index == 0)
        log("Mode resolved to Home...?", Severity::Warning);

    SetModeIndex(index);
}

uint GetCurrentModeIndex()
{
    const uint index = modeNames.Find(GetVariableString(Settings::VAR_MODE));
    return index < modes.Length ? index : 0;
}

bool SetModeIndex(const uint index)
{
    if (index >= modes.Length)
        return false;

    modeIndex = index; // for side effects!

    ModeDispatch();
    SetVariable(Settings::VAR_MODE, GetCurrentModeName());
    return true;
}

void ModeDispatch()
{
    @mode = modes[modeIndex];
}


// - Timestamps

ms tInit;    // The timestamp required to ensure that we can run an entire timerange.
ms tTrail;   // The timestamp that the trailing state is saved on.
ms tInput;   // The timestamp currently being evaluated.
ms tLimit;   // The timestamp that triggers the end of the simulation when the input time exceeds it.
ms tCleanup; // The timestamp of the inputs with the highest indices.

SimulationState@ initState;
SimulationState@ trailingState;

const vec3 NO_SPEED = vec3();
vec3 speed;

bool rewinding;

void RewindToInitState(SimulationManager@ sim)
{
    sim.RewindToState(initState);
    rewinding = true;
}

void RewindToTrailingState(SimulationManager@ sim)
{
    sim.RewindToState(trailingState);
    rewinding = true;
}


// - Inputs

array<uint> cache;
uint cacheMod;
uint cacheOffset;

// Keep up to date with InputType's 'length'.
const uint INPUT_TYPE_COUNT = 10;

void SetInput(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    switch (contextMode)
    {
    case ContextMode::Simulation:
        Sim::SetInput(sim, time, type, value);
    break;
    case ContextMode::Run:
        Run::SetInput(sim, time, type, value);
    break;
    default:
        Panic("Undefined ContextMode in SetInput");
    break;
    }
}

bool HasInputs(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    switch (contextMode)
    {
    case ContextMode::Simulation:
        Sim::HasInputs(sim, time, type, value);
    break;
    case ContextMode::Run:
        Run::HasInputs(sim, time, type, value);
    break;
    default:
        Panic("Undefined ContextMode in HasInputs");
    break;
    }
}

void RemoveInputs(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    switch (contextMode)
    {
    case ContextMode::Simulation:
        Sim::RemoveInputs(sim, time, type, value);
    break;
    case ContextMode::Run:
        Run::RemoveInputs(sim, time, type, value);
    break;
    default:
        Panic("Undefined ContextMode in RemoveInputs");
    break;
    }
}

void RemoveSteeringAhead(SimulationManager@ sim)
{
    switch (contextMode)
    {
    case ContextMode::Simulation:
        Sim::RemoveSteeringAhead(sim);
    break;
    case ContextMode::Run:
        Run::RemoveSteeringAhead(sim);
    break;
    default:
        Panic("Undefined ContextMode in RemoveSteeringAhead");
    break;
    }
}

InputCommand MakeInputCommand(const ms timestamp, const InputType type, const int state)
{
    InputCommand cmd;
    cmd.Timestamp = timestamp;
    cmd.Type = type;
    cmd.State = state;
    return cmd;
}


// - Results

class Result
{
    ms time;
    string inputs;
    SimulationState@ state;

    float Metric() const
    {
        return state.Dyna.CurrentState.LinearSpeed.LengthSquared();
    }
}

array<Result@> results;
uint resultIndex;

void SaveResult(SimulationManager@ sim)
{
    auto@ const buffer = sim.InputEvents;
    const auto@ const indices = buffer.Find(-1, InputType::FakeFinish);
    switch (indices.Length)
    {
    case 1:
        {
            const uint index = indices[0];
            auto event = buffer[index];
            buffer.RemoveAt(index);
            event.Time = tInput + 100000; // tmi offset minus a tick
            buffer.Add(event);
        }
    break;
    case 0:
        // Do we need to add in this case?
    break;
    default:
        print("Unexpected amount of FakeFinish inputs...", Severity::Error);
    break;
    }

    resultInputs[resultIndex] = buffer.ToCommandsText();
    @resultStates[resultIndex] = sim.SaveState();
}

bool NextResult()
{
    Assert(resultIndex <= results.Length);
    if (resultIndex == results.Length)
        return false;

    tInput = results[resultIndex++].time;
    tTrail = tInput - TICK;
    return true;
}

void PrepareResult(SimulationManager@ sim)
{
    if (contextMode == ContextMode::Simulation)
        BufferReplaceInputEvents(sim.InputEvents, initialEvents);
    RewindToInitState(sim);
    modeOnBegin(sim);
}

string GetBestInputs()
{
    uint bestIndex = 0;
    float best = results[bestIndex].Metric();
    const uint len = resultStates.Length;
    for (uint i = 1; i < len; i++)
    {
        if (results[i].state is null)
            break;

        const float other = results[i].Metric();
        if (best < other)
        {
            best = other;
            bestIndex = i;
        }
    }
    return resultInputs[bestIndex];
}


} // namespace Core

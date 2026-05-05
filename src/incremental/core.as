namespace Core
{


bool handleFinish;
string saveStateName;

void Begin(SimulationManager@ sim)
{
    speed = vec3();

    int timerange = (Settings::varEvalBeginStop - Settings::varEvalBeginStart) / 10 + 1;
    if (timerange < 1)
        timerange = 1;
    results.Resize(timerange);

    resultIndex = 0;

    tInit = Settings::varEvalBeginStart - 10;
    tInput = -10; // Just to detect if/when we are forgetting to set it later.
    tLimit = Settings::varEvalEnd;

    handleFinish = true;

    // TODO: find out where this came from.
    if (ShouldTryLoadingSaveState())
    {
        saveStateName = Settings::varSaveStateName;
        onStep = OnStepState::SAVE_STATE;
    }
    else
    {
        onStep = OnStepState::INIT;
    }

    ResolveModeIndex();

    string s;
    s += "\n\n";
    s += TITLE;
    s += " w/ ";
    s += GetCurrentModeName();
    s += "\n\n";
    print(s);

    mode.OnBegin(sim);
}

void Step(SimulationManager@ sim)
{
    const ms time = sim.TickTime;
    switch (onStep)
    {
    case OnStepState::NONE:
        PanicLog("Should not be able to reach this...");
    break;
    case OnStepState::SAVE_STATE:
        {
            SimulationStateFile stateFile;
            string error;
            if (!stateFile.Load(saveStateName, error))
            {
                print("There was an error with the savestate:", Severity::Error);
                print(error, Severity::Error);
                break;
            }

            const ms stateFileTime = stateFile.ToState().PlayerInfo.RaceTime;
            if (stateFileTime >= tInit)
            {
                string s;
                s += "Attempted to load state that occurs too late! ";
                s += stateFileTime;
                s += " is not less than ";
                s += tInit;
                print(s, Severity::Warning);
                break;
            }

            // NOTE: Not using Rewind functions here, since any inputs that were done on the same tick are long lost...
            sim.RewindToState(stateFile);
        }
    break;
    case OnStepState::INIT:
        if (time < tInit)
            break;

        Assert(time == tInit);
        @initState = sim.SaveState();
        onStep = OnStepState::MAIN;
    break;
    case OnStepState::MAIN:
        if (tInput <= tLimit)
        {
            if (time == tTrail)
            {
                @trailingState = sim.SaveState();
                break;
            }

            if (time < tInput)
                break;

            if (speed == NO_SPEED && time == tInput)
                speed = sim.Dyna.RefStateCurrent.LinearSpeed;

            modeOnStep(sim);
        }
        else
        {
            print(); // bit of spacing

            SaveResult(sim);
            if (NextResult())
                PrepareResult(sim);
            else
                Finish(sim);
        }
    break;
    case OnStepState::FINISH:
        if (handleFinish)
            Finish(sim);

        if (contextMode == ContextMode::Simulation)
            sim.ForceFinish();
    break;
    default:
        PanicLog("Undefined OnStepState in Core::Step");
    break;
    }
}

void End(SimulationManager@ sim)
{
    handleFinish = false;

    mode.onEnd(sim);

    const string filename = GetVariableString("bf_result_filename");
    CommandList script;
    script.Content = GetBestInputs();
    if (script.Save(filename))
        print("Inputs saved! Filename: " + filename, Severity::Success);
    else
        print("Inputs not saved! Filename: " + filename, Severity::Error);

    @initState = null;
    @trailingState = null;
    cache.Clear();
    results.Clear();
}


vec3 speed;

void Advance()
{
    speed = vec3();

    tInput += 10;

    const uint cacheLen = cache.Length;
    if (cacheLen == 0)
        return;

    for (uint i = cacheOffset; i < cacheLen; i += cacheMod)
        cache[i] = 0;
    cacheOffset = (cacheOffset + 1) % cacheMod;
}

void Finish(SimulationManager@ sim)
{
    handleFinish = false;
    onStep = OnStepState::FINISH;
    if (contextMode == ContextMode::Run)
        soState = SimOnlyState::END;
}


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

const string& GetCurrentModeName()
{
    return modeNames[modeIndex];
}

void OnModeIndex(const uint index)
{
    if (SetModeIndex(index))
        return;

    string s;
    s += "Mode Index went out of bounds... (";
    s += index;
    s += " >= ";
    s += modes.Length;
    s += ")";
    log(s, Severity::Warning);
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


ms tInit;    // The time required to ensure that we can run an entire timerange.
ms tInput;   // The time currently being evaluated.
ms tLimit;   // The time that triggers the end of the iteration when the input time exceeds it.

SimulationState@ initState;
SimulationState@ inputState;


array<uint> cache;
uint cacheMod;
uint cacheOffset;

void SetInput(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    const uint relativeTick = (time - tInput) / 10;
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

    // IDEA: invalidate cache more granularly?
    if (buffer.Length < len)
        cache.Clear();
}

void RemoveSteeringAhead(SimulationManager@ sim)
{
    auto@ const buffer = sim.InputEvents;
    const uint len = buffer.Length;
    BufferRemoveFromTime(buffer, tInput, { InputType::Left, InputType::Right, InputType::Steer });

    // IDEA: invalidate cache more granularly?
    if (buffer.Length < len)
        cache.Clear();
}


class Result
{
    string inputs;
    SimulationState@ state;

    Result(SimulationManager@ sim)
    {
        inputs = sim.InputEvents.ToCommandsText();
        state = sim.SaveState();
    }

    float Metric() const
    {
        return state.Dyna.CurrentState.LinearSpeed.LengthSquared();
    }
}

array<Result@> results;
uint resultIndex;

void SaveResult(SimulationManager@ sim)
{
    @results[resultIndex] = Result(sim);
}

bool NextResult()
{
    const uint len = results.Length;
    Assert(resultIndex <= len);
    if (resultIndex == len)
        return false;

    tInput = tInit + (len - resultIndex++) * 10;
    return true;
}

void PrepareResult(SimulationManager@ sim)
{
    RewindRemove(sim, initState);
    mode.OnBegin(sim);
}

const string& GetBestInputs()
{
    Result@ bestResult = results[0];
    if (bestResult is null)
        return "# Incremental did not complete a pass.";

    float bestMetric = bestResult.Metric();
    const uint len = results.Length;
    for (uint i = 1; i < len; ++i)
    {
        Result@ result = results[i];
        if (result is null)
            break;

        const float metric = result.Metric();
        if (bestMetric < metric)
        {
            bestMetric = metric;
            @bestResult = result;
        }
    }
    return bestResult.inputs;
}


} // namespace Core

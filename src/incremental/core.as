namespace Core
{


bool handleFinish;
string saveStateName;

void Begin(SimulationManager@ sim)
{
    int timerange = (Settings::varEvalBeginStop - Settings::varEvalBeginStart) / 10 + 1;
    if (timerange < 1)
        timerange = 1;
    results.Resize(timerange);

    resultIndex = 0;

    tInit = Settings::varEvalBeginStart - 10;
    tInput = -10; // Just to detect if/when we are forgetting to set it later.
    tLimit = Settings::varEvalEnd;

    handleFinish = true;

    if (VarGetBool(Settings::VAR_USE_SAVE_STATE))
    {
        saveStateName = VarGetString(Settings::VAR_SAVE_STATE_NAME);
        onStep = OnStepState::SAVE_STATE;
    }
    else
    {
        onStep = OnStepState::INIT;
    }

    const uint index = GetCurrentModeIndex();
    if (index == 0)
        log("Mode resolved to Home...?", Severity::Warning);
    SetModeIndex(index);

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

            // NOTE: Not using Rewind wrappers here, since any inputs that were done on the same tick are long lost...
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
            if (time < tInput)
                break;

            if (time == tInput)
                @inputState = sim.SaveState();

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

    const string filename = VarGetString("bf_result_filename");
    CommandList script;
    script.Content = GetBestInputs();
    if (script.Save(filename))
        print("Inputs saved! Filename: " + filename, Severity::Success);
    else
        print("Inputs not saved! Filename: " + filename, Severity::Error);

    @initState = null;
    @inputState = null;
    results.Clear();
}


void Advance()
{
    tInput += 10;
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

uint GetCurrentModeIndex()
{
    const uint index = modeNames.Find(VarGetString(Settings::VAR_MODE));
    return index < modes.Length ? index : 0;
}

bool SetModeIndex(const uint index)
{
    if (index >= modes.Length)
        return false;

    modeIndex = index;

    @mode = modes[modeIndex];
    SetVariable(Settings::VAR_MODE, GetCurrentModeName());
    return true;
}


ms tInit;    // The time required to ensure that we can run an entire timerange.
ms tInput;   // The time currently being evaluated.
ms tLimit;   // The time that triggers the end of the iteration when the input time exceeds it.

SimulationState@ initState;
SimulationState@ inputState;

int GetRelativeTick(const ms absoluteTime)
{
    return (absoluteTime - tInput) / 10;
}

ms GetRelativeTime(const ms absoluteTime)
{
    return absoluteTime - tInput;
}

ms GetAbsoluteTime(const ms relativeTime)
{
    return tInput + relativeTime;
}


bool GetInput(SimulationManager@ sim, const ms time, const InputType type, int &out value)
{
    const auto@ const buffer = sim.InputEvents;

    const ums timestamp = IEB_TIME_OFFSET + time;
    const int eventIndex = EventIndicesEncode(buffer.EventIndices, type);
    const uint bufferIndex = BufferSearchTimestamp(buffer, timestamp, -1);
    const uint bufferLen = buffer.Length;
    for (uint i = bufferIndex; i < bufferLen; ++i)
    {
        const TM::InputEvent inputEvent = buffer[i];
        if (inputEvent.Time > timestamp)
            break;

        TM::InputEventValue inputEventValue = inputEvent.Value;
        if (inputEventValue.EventIndex == eventIndex)
        {
            value = InputEventValueGetInt(inputEventValue, type);
            return true;
        }
    }

    value = 0;
    return false;
}

void SetInput(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    auto@ const buffer = sim.InputEvents;
    uint index = 0;

    const ums timestamp = IEB_TIME_OFFSET + time;
    const int eventIndex = EventIndicesEncode(buffer.EventIndices, type);

    {
        const uint bufferIndex = BufferSearchTimestamp(buffer, timestamp, -1);
        for (uint i = bufferIndex; i < buffer.Length; ++i)
        {
            const TM::InputEvent inputEvent = buffer[i];
            if (inputEvent.Time > timestamp)
                break;

            if (inputEvent.Value.EventIndex == eventIndex)
            {
                index = i;
                break;
            }
        }
    }

    if (index == 0)
    {
        buffer.Add(time, type, value);

        const uint bufferIndex = BufferSearchTimestamp(buffer, timestamp, -1);
        for (uint i = bufferIndex; i < buffer.Length; ++i)
        {
            const TM::InputEvent inputEvent = buffer[i];
            if (inputEvent.Value.EventIndex == eventIndex)
            {
                Assert(inputEvent.Time == timestamp);
                index = i;
                break;
            }
        }
        Assert(index != 0);
    }

    InputEventSetInt(buffer[index], type, value);
}

void RemoveInputs(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    auto@ const buffer = sim.InputEvents;
    BufferRemoveIndices(buffer, buffer.Find(time, type, value));
}

void RemoveFromInputTime(SimulationManager@ sim, const array<InputType>@ inputTypes)
{
    BufferRemoveFromTime(sim.InputEvents, tInput, inputTypes);
}


class Result
{
    string inputs;
    float metric;

    Result(SimulationManager@ sim)
    {
        inputs = sim.InputEvents.ToCommandsText();
        metric = sim.Dyna.RefStateCurrent.LinearSpeed.LengthSquared();
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

    const uint len = results.Length;
    for (uint i = 1; i < len; ++i)
    {
        Result@ result = results[i];
        if (result is null)
            break;

        if (bestResult.metric < result.metric)
            @bestResult = result;
    }
    return bestResult.inputs;
}


} // namespace Core

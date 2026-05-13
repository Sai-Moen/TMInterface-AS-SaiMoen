namespace Core
{


const string VAR = ID + "_";

const string VAR_MODE = VAR + "mode";

const string VAR_LOCK_TIMERANGE   = VAR + "lock_timerange";
const string VAR_EVAL_BEGIN_START = VAR + "eval_begin_start";
const string VAR_EVAL_BEGIN_STOP  = VAR + "eval_begin_stop";
const string VAR_EVAL_END         = VAR + "eval_end";

const string VAR_USE_SAVE_STATE  = VAR + "use_save_state";
const string VAR_SAVE_STATE_NAME = VAR + "save_state_name";

const string VAR_SHOW_INFO = VAR + "show_info";

const string VAR_RUN_REPLAY_TIME = VAR + "run_replay_time";

void SettingsRegister()
{
    RegisterVariable(VAR_MODE, "");

    RegisterVariable(VAR_LOCK_TIMERANGE, true);
    RegisterVariable(VAR_EVAL_BEGIN_START, 0);
    RegisterVariable(VAR_EVAL_BEGIN_STOP, 0);
    RegisterVariable(VAR_EVAL_END, 0);

    RegisterVariable(VAR_USE_SAVE_STATE, false);
    RegisterVariable(VAR_SAVE_STATE_NAME, "");

    RegisterVariable(VAR_SHOW_INFO, true);

    RegisterVariable(VAR_RUN_REPLAY_TIME, 0);
}

void SettingsRender()
{
    if (UI::CollapsingHeader("General"))
    {
        UI::BeginDisabled(mode.singleIteration);
        const bool lockTimerange = UI::CheckboxVar("Lock Timerange", VAR_LOCK_TIMERANGE);
        UI::EndDisabled();

        if (mode.singleIteration)
            TooltipOnHover("The currently selected mode does not support an unlocked timerange.");
        else
            TooltipOnHover("Enabling this will set Evaluation Begin Stop Time equal to Evaluation Begin Start Time.");

        if (UI::Button("Reset timestamps to 0"))
        {
            VarSetMs(VAR_EVAL_BEGIN_START, 0);
            VarSetMs(VAR_EVAL_BEGIN_STOP, 0);
            VarSetMs(VAR_EVAL_END, 0);
        }

        const ms evalBeginStart = UI::InputTimeVar("Evaluation Begin Starting Time", VAR_EVAL_BEGIN_START);
        if (mode.singleIteration || lockTimerange)
        {
            UI::BeginDisabled();
            UI::InputTime("Evaluation Begin Stopping Time", evalBeginStart);
            UI::EndDisabled();
        }
        else
        {
            UI::InputTimeVar("Evaluation Begin Stopping Time", VAR_EVAL_BEGIN_STOP);
        }
        UI::InputTimeVar("Evaluation End Time", VAR_EVAL_END);

        UI::Separator();

        const bool useSaveState = UI::CheckboxVar("Start from Save State", VAR_USE_SAVE_STATE);
        UI::BeginDisabled(!useSaveState);
        UI::InputTextVar("Save State name", VAR_SAVE_STATE_NAME);
        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Modes"))
    {
        ComboHelper("Mode", modeNames, modeIndex, ModeIndexCallback);
        UI::Separator();

        mode.draw();
    }

    if (UI::CollapsingHeader("Run-Mode"))
    {
        UI::TextWrapped(
            "Run-Mode Bruteforce is an alternative to Simulation,"
            " where the plugin runs during a race rather than on a replay file");

        UI::Separator();

        UI::InputTimeVar("Replay Time", VAR_RUN_REPLAY_TIME);
        TooltipOnHover("This is the equivalent to the replay time when using simulation mode.");
        if (UI::Button("Start Run-Mode Bruteforce"))
            runState = RunState::INIT1;
    }

    if (UI::CollapsingHeader("Misc"))
    {
        UI::CheckboxVar("Show Info", VAR_SHOW_INFO);
        TooltipOnHover("Show additional information about the simulation.");
    }
}

IncMode@ Home()
{
    IncMode home;
    home.draw =
        function()
        {
            string s;
            s += "Loading: ";
            s += modeNames[modeIndex];
            s += CharRepeat(Time::Now % 3 + 1, '.');
            UI::TextWrapped(s);

            // TODO: uncomment.
            // const uint index = ModeIndexDetermineByName();
            // if (index != 0)
            //     ModeIndexTrySet(index);
        }
    ;
    return home;
}


bool handleFinish;

void Initialize()
{
    const uint index = ModeIndexDetermineByName();
    if (index == 0)
        log("Mode resolved to Home...?", Severity::Warning);
    ModeIndexTrySet(index);

    const ms evalBeginStart = VarGetMs(VAR_EVAL_BEGIN_START);
    const ms evalBeginStop  = VarGetMs(VAR_EVAL_BEGIN_STOP);

    tInit = evalBeginStart - 20;
    tInput = -10; // Just to detect if/when we are forgetting to set it later.
    tLimit = VarGetMs(VAR_EVAL_END);

    int timerange = (evalBeginStop - evalBeginStart) / 10 + 1;
    if (timerange < 1)
        timerange = 1;
    results.Resize(timerange);

    resultIndex = 0;

    preventSimulationFinish = true;
    handleFinish = true;

    stepState = VarGetBool(VAR_USE_SAVE_STATE) ? StepState::SAVE_STATE : StepState::INIT;
}

void Begin(SimulationManager@ sim)
{
    string s;
    s += "\n\n Incremental w/ ";
    s += modeNames[modeIndex];
    s += "\n\n";
    print(s);

    mode.begin(sim);
}

void Step(SimulationManager@ sim)
{
    const ms time = sim.TickTime;
    switch (stepState)
    {
    case StepState::NONE:
        PanicLog("Should not be able to reach this...");
    break;
    case StepState::SAVE_STATE:
        {
            // Regardless of what happens, we will go to this state next.
            stepState = StepState::INIT;

            SimulationStateFile stateFile;
            string error;
            if (!stateFile.Load(VarGetString(VAR_SAVE_STATE_NAME), error))
            {
                string s;
                s += "There was an error with the savestate:\n";
                s += error;
                print(s, Severity::Error);
                break;
            }

            const ms stateFileTime = stateFile.ToState().PlayerInfo.RaceTime;
            if (stateFileTime >= tInit)
            {
                string s;
                s += "Attempted to load state that occurs too late! ";
                s += stateFileTime;
                s += " >= ";
                s += tInit;
                print(s, Severity::Warning);
                break;
            }

            // NOTE: Not using Rewind wrappers here, since any inputs that were done on the same tick are long lost...
            sim.RewindToState(stateFile);
        }
    break;
    case StepState::INIT:
        if (time < tInit)
            break;

        Assert(time == tInit);
        @initState = sim.SaveState();
        stepState = StepState::ITER;
    break;
    case StepState::ITER:
        tInput = (tInit + 10) + (results.Length - resultIndex) * 10;
        mode.iteration(sim);
        stepState = StepState::STEP;
    break;
    case StepState::STEP:
        if (tInput <= tLimit)
        {
            if (time < tInput)
                break;

            if (time == tInput)
                @inputState = sim.SaveState();

            mode.step(sim);
        }
        else
        {
            print();

            // TODO: add delay?
            @results[resultIndex++] = Result(sim);
            if (resultIndex == results.Length)
            {
                Finish(sim);
                break;
            }

            // TODO: proper rewind...
            RewindRemove(sim, initState);
            stepState = StepState::ITER;
        }
    break;
    case StepState::FINISH:
        if (handleFinish)
            Finish(sim);

        if (contextMode == ContextMode::Simulation)
            sim.ForceFinish();
    break;
    default:
        PanicLog("Undefined StepState in Core::Step");
    break;
    }
}

void End(SimulationManager@ sim)
{
    preventSimulationFinish = false;
    handleFinish = false;

    mode.end(sim);

    const string filename = VarGetString("bf_result_filename");
    CommandList script;
    script.Content = GetBestInputs();
    if (script.Save(filename))
        print("Inputs saved! Filename: " + filename, Severity::Success);
    else
        print("Inputs not saved! Filename: " + filename, Severity::Error);

    @initState = null;
    @inputState = null;
    postInitInputEvents.Clear();
    results.Clear();
}


void Advance(const array<InputCommand>@ commands)
{
    string s;
    s += tInput;
    s += ":\n";

    if (VarGetBool(VAR_SHOW_INFO))
    {
        const float mps = inputState.Dyna.CurrentState.LinearSpeed.Length();

        s += "Speed (km/h): ";
        s += FormatPrecise(mps * 3.6);
        s += "\n";
    }

    for (uint i = 0; i < commands.Length; i++)
    {
        s += commands[i].ToString();
        s += "\n";
    }

    print(s);


    tInput += 10;
}

void Finish(SimulationManager@ sim)
{
    handleFinish = false;
    stepState = StepState::FINISH;
    if (contextMode == ContextMode::Run)
        runState = RunState::END;
}


array<string> modeNames;
array<IncMode@> modes;
uint modeIndex;
IncMode@ mode;

void ModeIndexCallback(const uint index)
{
    if (ModeIndexTrySet(index))
        return;

    string s;
    s += "Mode Index went out of bounds... (";
    s += index;
    s += " >= ";
    s += modes.Length;
    s += ")";
    log(s, Severity::Warning);
}

uint ModeIndexDetermineByName()
{
    const uint index = modeNames.Find(VarGetString(VAR_MODE));
    return index < modes.Length ? index : 0;
}

bool ModeIndexTrySet(const uint index)
{
    if (index >= modes.Length)
        return false;

    modeIndex = index;

    @mode = modes[modeIndex];
    SetVariable(VAR_MODE, modeNames[modeIndex]);
    return true;
}


ms tInit;  // The time required to ensure that we can run all iterations.
SimulationState@ initState;
ms tInput; // The time currently being evaluated.
SimulationState@ inputState;
ms tLimit; // The time that triggers the end of the iteration when the input time exceeds it.

array<TM::InputEvent> postInitInputEvents;
uint preservationIndex;

ms GetRelativeTime(const ms absoluteTime)
{
    return absoluteTime - tInput;
}

ms GetAbsoluteTime(const ms relativeTime)
{
    return tInput + relativeTime;
}

void SetPostInitInputEvents(const TM::InputEventBuffer@ buffer)
{
    const uint index = BufferSearchTime(buffer, tInit, -1);
    SetPostInitInputEvents(buffer, index);
}

void SetPostInitInputEvents(const TM::InputEventBuffer@ buffer, const uint index)
{
    const uint bufferLen = buffer.Length;
    Assert(bufferLen >= index);

    postInitInputEvents.Resize(bufferLen - index);
    for (uint i = index; i < bufferLen; ++i)
        postInitInputEvents[i - index] = buffer[i];
}


bool GetInput(SimulationManager@ sim, const ms time, const InputType type, int &out value)
{
    auto@ const buffer = sim.InputEvents;

    const ums timestamp = IEB_TIME_OFFSET + time;
    const int eventIndex = EventIndicesEncode(buffer.EventIndices, type);

    const uint index = BufferFindFirst(buffer, timestamp, eventIndex);
    if (index == 0)
    {
        value = 0;
        return false;
    }

    BufferRemoveDuplicatesAtTimestamp(buffer, timestamp, eventIndex, index);
    value = InputEventGetInt(buffer[index], type);
    return true;
}

void SetInput(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    auto@ const buffer = sim.InputEvents;

    const ums timestamp = IEB_TIME_OFFSET + time;
    const int eventIndex = EventIndicesEncode(buffer.EventIndices, type);

    uint index = BufferFindFirst(buffer, timestamp, eventIndex);
    if (index == 0)
    {
        buffer.Add(time, type, value);

        const uint bufferIndex = BufferSearchTimestamp(buffer, timestamp, -1);
        const uint bufferLen = buffer.Length;
        for (uint i = bufferIndex; i < bufferLen; ++i)
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
    else
    {
        // If we didn't find anything the first time around, then there cannot be any duplicates.
        BufferRemoveDuplicatesAtTimestamp(buffer, timestamp, eventIndex, index);
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

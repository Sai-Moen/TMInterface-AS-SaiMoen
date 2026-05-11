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
        ComboHelper("Mode", modeNames, modeIndex, OnModeIndex);
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
            soState = SimOnlyState::INIT1;
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
            UI::TextWrapped("Hello!");

            const uint index = GetCurrentModeIndex();
            if (index != 0)
                SetModeIndex(index);
        }
    ;
    return home;
}


bool handleFinish;

void Begin(SimulationManager@ sim)
{
    const ms evalBeginStart = VarGetMs(VAR_EVAL_BEGIN_START);
    const ms evalBeginStop  = VarGetMs(VAR_EVAL_BEGIN_STOP);

    int timerange = (evalBeginStop - evalBeginStart) / 10 + 1;
    if (timerange < 1)
        timerange = 1;
    results.Resize(timerange);

    resultIndex = 0;

    tInit = evalBeginStart - 10;
    tInput = -10; // Just to detect if/when we are forgetting to set it later.
    tLimit = VarGetMs(VAR_EVAL_END);

    handleFinish = true;

    stepState = VarGetBool(VAR_USE_SAVE_STATE) ? StepState::SAVE_STATE : StepState::INIT;

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
            SimulationStateFile stateFile;
            string error;
            if (!stateFile.Load(VarGetString(VAR_SAVE_STATE_NAME), error))
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
    case StepState::INIT:
        if (time < tInit)
            break;

        Assert(time == tInit);
        @initState = sim.SaveState();
        stepState = StepState::ITER;
    break;
    case StepState::ITER:
        mode.iteration(sim);
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

            const uint index = resultIndex;
            @results[resultIndex++] = Result(sim);

            const uint length = results.Length;
            Assert(resultIndex <= length);
            if (resultIndex == length)
            {
                Finish(sim);
                break;
            }

            tInput = tInit + (length - index) * 10;
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
        soState = SimOnlyState::END;
}


array<string> modeNames;
array<IncMode@> modes;
uint modeIndex;
IncMode@ mode;

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

const string& GetCurrentModeName()
{
    return modeNames[modeIndex];
}

uint GetCurrentModeIndex()
{
    const uint index = modeNames.Find(VarGetString(VAR_MODE));
    return index < modes.Length ? index : 0;
}

bool SetModeIndex(const uint index)
{
    if (index >= modes.Length)
        return false;

    modeIndex = index;

    @mode = modes[modeIndex];
    SetVariable(VAR_MODE, GetCurrentModeName());
    return true;
}


ms tInit;    // The time required to ensure that we can run an entire timerange.
ms tInput;   // The time currently being evaluated.
ms tLimit;   // The time that triggers the end of the iteration when the input time exceeds it.

SimulationState@ initState;
SimulationState@ inputState;

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

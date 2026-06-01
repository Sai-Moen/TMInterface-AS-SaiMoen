namespace Core
{


const string VAR = "incremental_";

const string VAR_EVAL_ITER_BEGIN  = VAR + "eval_iter_begin";
const string VAR_EVAL_ITER_END    = VAR + "eval_iter_end";
const string VAR_EVAL_END         = VAR + "eval_end";

const string VAR_USE_SAVE_STATE  = VAR + "use_save_state";
const string VAR_SAVE_STATE_NAME = VAR + "save_state_name";

const string VAR_PRINT_EXTRA_INFO          = VAR + "print_extra_info";
const string VAR_TERMINAL_TITLE_INFO_LEVEL = VAR + "terminal_title_info_level";
const string VAR_RUN_REPLAY_TIME           = VAR + "run_replay_time";
const string VAR_MODE                      = VAR + "mode";

uint varTerminalTitleInfoLevel;

void Register()
{
    RegisterVariable(VAR_EVAL_ITER_BEGIN, 0);
    RegisterVariable(VAR_EVAL_ITER_END, 0);
    RegisterVariable(VAR_EVAL_END, 0);

    RegisterVariable(VAR_USE_SAVE_STATE, false);
    RegisterVariable(VAR_SAVE_STATE_NAME, "");

    RegisterVariable(VAR_PRINT_EXTRA_INFO, true);
    RegisterVariable(VAR_TERMINAL_TITLE_INFO_LEVEL, 0);
    RegisterVariable(VAR_RUN_REPLAY_TIME, 0);
    RegisterVariable(VAR_MODE, "");

    varTerminalTitleInfoLevel = VarGetUint(VAR_TERMINAL_TITLE_INFO_LEVEL);
    if (varTerminalTitleInfoLevel >= TerminalTitleInfoLevel::COUNT)
    {
        varTerminalTitleInfoLevel = TerminalTitleInfoLevel::NONE;
        VarSetUint(VAR_TERMINAL_TITLE_INFO_LEVEL, varTerminalTitleInfoLevel);
    }
}

enum TerminalTitleInfoLevel
{
    NONE,
    ITERATION,
    COMMIT,

    COUNT
}

const array<string> TERMINAL_TITLE_INFO_LEVEL_NAMES =
{
    "None",
    "Iteration",
    "Commit"
};

void Draw()
{
    if (modeIndex == 0)
    {
        const uint index = ModeIndexDetermineByName();
        if (index != 0)
        {
            string s;
            s += "Loading: ";
            s += modeNames[modeIndex];
            s += CharRepeat(Time::Now % 4, '.');
            UI::TextWrapped(s);

            ModeIndexTrySet(index);
        }
    }

    if (UI::CollapsingHeader("General"))
    {
        if (UI::Button("Reset timestamps to 0"))
        {
            VarSetTime(VAR_EVAL_ITER_BEGIN, 0);
            VarSetTime(VAR_EVAL_ITER_END, 0);
            VarSetTime(VAR_EVAL_END, 0);
        }

        const ms evalIterBegin = UI::InputTimeVar("Evaluation Iteration Begin Time", VAR_EVAL_ITER_BEGIN);
        TooltipOnHover("The lower bound (inclusive) of iteration times.");

        ms evalIterEnd;
        if (mode.singleIteration)
        {
            evalIterEnd = evalIterBegin;
            VarSetTime(VAR_EVAL_ITER_END, evalIterEnd);

            UI::InputTime("Evaluation Iteration End Time", evalIterEnd);
            TooltipOnHover("The currently selected mode only supports a single iteration.");
        }
        else
        {
            evalIterEnd = UI::InputTimeVar("Evaluation Iteration End Time", VAR_EVAL_ITER_END);
            if (evalIterEnd < evalIterBegin)
            {
                evalIterEnd = evalIterBegin;
                VarSetTime(VAR_EVAL_ITER_END, evalIterEnd);
            }
            TooltipOnHover("The upper bound (inclusive) of iteration times.");
        }

        ms evalEnd = UI::InputTimeVar("Evaluation End Time", VAR_EVAL_END);
        if (evalEnd != 0 && evalEnd < evalIterEnd)
        {
            evalEnd = evalIterEnd;
            VarSetTime(VAR_EVAL_END, evalEnd);
        }
        TooltipOnHover(
            "If the input time is beyond this time, a new iteration is started.\n"
            "Set to 0 to have it be set to the events duration automatically.");

        UI::Separator();

        const bool useSaveState = UI::CheckboxVar("Start from Save State", VAR_USE_SAVE_STATE);
        UI::BeginDisabled(!useSaveState);
        UI::InputTextVar("Save State name", VAR_SAVE_STATE_NAME);
        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Modes"))
    {
        ComboSelectIndex("Mode", modeNames, modeIndex, ModeIndexCallback);

        UI::Separator();
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
        TooltipOnHover(
            "This is equivalent to the replay time (events duration) in Simulation.\n"
            "Inputs after this time will not be used.");

        if (UI::Button("Start Run-Mode Bruteforce"))
            runState = RunState::INIT1;
    }

    if (UI::CollapsingHeader("Misc"))
    {
        UI::CheckboxVar("Print Extra Info", VAR_PRINT_EXTRA_INFO);
        TooltipOnHover("Print additional information about the simulation to the bruteforce terminal.");

        ComboSelectIndex(
            "Terminal Title Info Level",
            TERMINAL_TITLE_INFO_LEVEL_NAMES,
            varTerminalTitleInfoLevel,
            TerminalTitleInfoLevelCallback);
    }
}

void TerminalTitleInfoLevelCallback(const uint index)
{
    varTerminalTitleInfoLevel = index;
    VarSetUint(VAR_TERMINAL_TITLE_INFO_LEVEL, varTerminalTitleInfoLevel);
}

void TerminalTitleInit(string& s)
{
    s += "Incremental";
}

void TerminalTitleAppendIterationInfo(string& s)
{
    s += " | Iteration: ";
    s += resultIndex + 1;
    s += " / ";
    s += results.Length;
}

void TerminalTitleAppendCommitInfo(string& s)
{
    s += " | Commit: ";
    s += tInput;
    s += "ms / ";
    s += tLimit;
    s += "ms";
}

IncMode@ Home()
{
    IncMode home;
    @home.draw = HomeDraw;
    return home;
}

void HomeDraw()
{
    UI::TextWrapped("Currently loaded modes:");

    UI::Separator();

    for (uint i = 0; i < modeNames.Length; ++i)
        UI::TextWrapped(modeNames[i]);

    UI::Separator();
}


bool handleFinish;

void Initialize(const ms alternativeTimeLimit)
{
    const uint index = ModeIndexDetermineByName();
    if (index == 0)
        log("Mode resolved to Home...?", Severity::Warning);
    ModeIndexTrySet(index);

    const ms evalIterBegin = VarGetTime(VAR_EVAL_ITER_BEGIN);
    const ms evalIterEnd   = VarGetTime(VAR_EVAL_ITER_END);
    const ms evalEnd       = VarGetTime(VAR_EVAL_END);

    varTerminalTitleInfoLevel = VarGetUint(VAR_TERMINAL_TITLE_INFO_LEVEL);
    if (varTerminalTitleInfoLevel >= TerminalTitleInfoLevel::COUNT)
    {
        varTerminalTitleInfoLevel = TerminalTitleInfoLevel::NONE;
        VarSetUint(VAR_TERMINAL_TITLE_INFO_LEVEL, varTerminalTitleInfoLevel);
    }

    tInit = evalIterBegin;
    tInput = -10; // Detecting uninitialized usage.
    tLimit = evalEnd != 0 ? evalEnd : alternativeTimeLimit;
    preservationIndex = uint(-1); // Detecting uninitialized usage.

    int timerange;
    if (mode.singleIteration)
    {
        timerange = 1;
    }
    else
    {
        timerange = (evalIterEnd - evalIterBegin) / 10 + 1;
        if (timerange < 1)
            timerange = 1;
    }
    results.Resize(timerange);
    resultIndex = 0;

    stepState = VarGetBool(VAR_USE_SAVE_STATE) ? StepState::SAVE_STATE : StepState::INIT;
    preventSimulationFinish = true;
    handleFinish = true;
}

void Begin(SimulationManager@ sim)
{
    if (varTerminalTitleInfoLevel == TerminalTitleInfoLevel::NONE)
    {
        string s;
        TerminalTitleInit(s);
        SetConsoleWindowTitle(s);
    }

    string s;
    s += "\n\n  Incremental w/ ";
    s += modeNames[modeIndex];
    s += "\n\n";
    print(s);

    mode.begin(sim);
}

void Iteration(SimulationManager@ sim)
{
    tInput = (tInit - 10) + (results.Length - resultIndex) * 10;
    preservationIndex = 0;
    PostInitInputEventsAdvance(sim.InputEvents);

    if (varTerminalTitleInfoLevel == TerminalTitleInfoLevel::ITERATION)
    {
        string s;
        TerminalTitleInit(s);
        TerminalTitleAppendIterationInfo(s);
        SetConsoleWindowTitle(s);
    }

    mode.iteration(sim);
}

void Step(SimulationManager@ sim)
{
    switch (stepState)
    {
    case StepState::NONE:
        Unreachable();
    break;
    case StepState::SAVE_STATE:
        {
            SimulationStateFile stateFile;
            string error;
            if (!stateFile.Load(VarGetString(VAR_SAVE_STATE_NAME), error))
            {
                string s;
                s += "There was an error with the savestate:\n";
                s += error;
                print(s, Severity::Error);

                Finish();
                break;
            }

            const ms stateFileTime = stateFile.ToState().PlayerInfo.RaceTime;
            if (stateFileTime > tInit)
            {
                string s;
                s += "Attempted to load state that occurs too late! ";
                s += Time::Format(stateFileTime);
                s += " > ";
                s += Time::Format(tInit);
                print(s, Severity::Error);

                Finish();
                break;
            }

            // Rewinding forwards, no point in RewindFlags::PRESERVE.
            sim.RewindToState(stateFile);
        }

        stepState = StepState::INIT;
    // fallthrough
    case StepState::INIT:
        {
            const ms time = sim.TickTime;
            if (time < tInit)
                break;

            Assert(time == tInit);
        }

        @initState = sim.SaveState();
        Iteration(sim);
        stepState = StepState::STEP;
    // fallthrough
    case StepState::STEP:
        {
            const ms time = sim.TickTime;
            if (tInput <= tLimit)
            {
                if (time < tInput)
                    break;

                if (time == tInput)
                    @inputState = sim.SaveState();

                mode.step(sim);
                break;
            }

            const ms checkTime = tLimit + 20;
            Assert(time <= checkTime);
            if (time != checkTime)
                break;
        }

        print();

        @results[resultIndex++] = Result(sim);
        if (resultIndex != results.Length)
        {
            Rewind(sim, initState, RewindFlags::REMOVE);
            Iteration(sim);
            break;
        }

        Assert(handleFinish);
    // fallthrough
    case StepState::FINISH:
        if (handleFinish)
            Finish();

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
    // Just for the GC.
    @initState = null;
    @inputState = null;
    postInitInputEvents.Clear();

    stepState = StepState::NONE;
    preventSimulationFinish = false;
    handleFinish = false;

    CommandList script;

    Result@ bestResult = results[0];
    if (bestResult is null)
    {
        script.Content = "# Incremental did not complete a pass.";
    }
    else
    {
        const uint len = results.Length;
        for (uint i = 1; i < len; ++i)
        {
            Result@ result = results[i];
            if (result is null)
                break;

            if (bestResult.metric < result.metric)
                @bestResult = result;
        }
        script.Content = bestResult.inputs;
    }
    results.Clear();

    const string filename = VarGetString("bf_result_filename");
    if (script.Save(filename))
        print("Inputs saved! Filename: " + filename, Severity::Success);
    else
        print("Inputs not saved! Filename: " + filename, Severity::Error);

    mode.end(sim);
}

void Finish()
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
ms tInput; // The time currently being evaluated.
ms tLimit; // The time that triggers the end of the iteration when the input time exceeds it.

SimulationState@ initState;
SimulationState@ inputState;

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

void PostInitInputEventsInitialize(const TM::InputEventBuffer@ ieb)
{
    PostInitInputEventsInitialize(ieb, IEBSearchTime(ieb, tInit));
}

void PostInitInputEventsInitialize(const TM::InputEventBuffer@ ieb, const uint iebIndex)
{
    const uint iebLen = ieb.Length;
    Assert(iebLen >= iebIndex);

    uint index = 0;
    postInitInputEvents.Resize(iebLen - iebIndex);
    const uint mask = EventIndicesMakeInputTypesBitmask(ieb.EventIndices, mode.preservationExclusions);
    for (uint i = iebIndex; i < iebLen; ++i)
    {
        const TM::InputEvent inputEvent = ieb[i];
        if (mask & 1 << inputEvent.Value.EventIndex == 0)
            postInitInputEvents[index++] = inputEvent;
    }
    postInitInputEvents.Resize(index);
}

void PostInitInputEventsCopyToIEB(TM::InputEventBuffer@ ieb)
{
    const uint len = postInitInputEvents.Length;
    for (uint i = preservationIndex; i < len; ++i)
        ieb.Add(postInitInputEvents[i]);
}

void PostInitInputEventsAdvance(TM::InputEventBuffer@ ieb)
{
    const ums timestamp = IEB_TIME_OFFSET + tInput;
    uint i;
    const uint len = postInitInputEvents.Length;
    for (i = preservationIndex; i < len; ++i)
    {
        const TM::InputEvent inputEvent = postInitInputEvents[i];
        if (inputEvent.Time >= timestamp)
            break;

        ieb.Add(inputEvent);
    }
    preservationIndex = i;
    PostInitInputEventsCopyToIEB(ieb);
}


bool InputGet(SimulationManager@ sim, const ms time, const InputType type, int &out value)
{
    auto@ const ieb = sim.InputEvents;

    const ums timestamp = IEB_TIME_OFFSET + time;
    const int eventIndex = EventIndicesEncode(ieb.EventIndices, type);

    const uint index = IEBFindFirst(ieb, timestamp, eventIndex);
    if (index == 0)
    {
        value = 0;
        return false;
    }

    IEBRemoveDuplicatesAtTimestamp(ieb, timestamp, eventIndex, index);
    value = InputEventGetInt(ieb[index], type);
    return true;
}

void InputSet(SimulationManager@ sim, const ms time, const InputType type, const int value)
{
    auto@ const ieb = sim.InputEvents;

    const ums timestamp = IEB_TIME_OFFSET + time;
    const int eventIndex = EventIndicesEncode(ieb.EventIndices, type);

    uint index = IEBFindFirst(ieb, timestamp, eventIndex);
    if (index == 0)
    {
        ieb.Add(time, type, value);

        const uint iebIndex = IEBSearchTimestamp(ieb, timestamp);
        const uint iebLen = ieb.Length;
        for (uint i = iebIndex; i < iebLen; ++i)
        {
            const TM::InputEvent inputEvent = ieb[i];
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
        IEBRemoveDuplicatesAtTimestamp(ieb, timestamp, eventIndex, index);
    }

    InputEventSetInt(ieb[index], type, value);
}

void InputRemove(SimulationManager@ sim, const ms time, const InputType type)
{
    IEBRemoveOneAtTime(sim.InputEvents, time, type);
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


} // namespace Core

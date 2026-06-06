namespace Core
{


const string VAR = "incremental_";

const string VAR_EVAL_FULL_REPLAY = VAR + "eval_full_replay";
const string VAR_EVAL_ITER_BEGIN  = VAR + "eval_iter_begin";
const string VAR_EVAL_ITER_END    = VAR + "eval_iter_end";
const string VAR_EVAL_END         = VAR + "eval_end";

const string VAR_USE_SAVE_STATE  = VAR + "use_save_state";
const string VAR_SAVE_STATE_NAME = VAR + "save_state_name";

const string VAR_PRINT_EXTRA_INFO          = VAR + "print_extra_info";
const string VAR_TERMINAL_TITLE_INFO_LEVEL = VAR + "terminal_title_info_level";
const string VAR_RUN_REPLAY_TIME           = VAR + "run_replay_time";
const string VAR_MODE                      = VAR + "mode";

void VarsRegister()
{
    RegisterVariable(VAR_EVAL_FULL_REPLAY, false);
    RegisterVariable(VAR_EVAL_ITER_BEGIN, 0);
    RegisterVariable(VAR_EVAL_ITER_END, 0);
    RegisterVariable(VAR_EVAL_END, 0);

    RegisterVariable(VAR_USE_SAVE_STATE, false);
    RegisterVariable(VAR_SAVE_STATE_NAME, "");

    RegisterVariable(VAR_PRINT_EXTRA_INFO, true);
    RegisterVariable(VAR_TERMINAL_TITLE_INFO_LEVEL, 0);
    RegisterVariable(VAR_RUN_REPLAY_TIME, 0);
    RegisterVariable(VAR_MODE, "");
}

bool varEvalFullReplay;
ms varEvalIterBegin;
ms varEvalIterEnd;
ms varEvalEnd;

bool varUseSaveState;
string varSaveStateName;

bool varPrintExtraInfo;
uint varTerminalTitleInfoLevel;
ms varRunReplayTime;

void VarsInit()
{
    varEvalFullReplay = VarGetBool(VAR_EVAL_FULL_REPLAY);
    varEvalIterBegin = VarGetTime(VAR_EVAL_ITER_BEGIN);
    varEvalIterEnd = VarGetTime(VAR_EVAL_ITER_END);
    if (varEvalIterEnd < varEvalIterBegin)
    {
        varEvalIterEnd = varEvalIterBegin;
        VarSetTime(VAR_EVAL_ITER_END, varEvalIterEnd);
    }

    varEvalEnd = VarGetTime(VAR_EVAL_END);
    if (varEvalEnd != 0 && varEvalEnd < varEvalIterEnd)
    {
        varEvalEnd = varEvalIterEnd;
        VarSetTime(VAR_EVAL_END, varEvalEnd);
    }

    varUseSaveState  = VarGetBool(VAR_USE_SAVE_STATE);
    varSaveStateName = VarGetString(VAR_SAVE_STATE_NAME);

    varPrintExtraInfo = VarGetBool(VAR_PRINT_EXTRA_INFO);

    varTerminalTitleInfoLevel = VarGetUint(VAR_TERMINAL_TITLE_INFO_LEVEL);
    if (varTerminalTitleInfoLevel >= TerminalTitleInfoLevel::COUNT)
    {
        varTerminalTitleInfoLevel = TerminalTitleInfoLevel::NONE;
        VarSetUint(VAR_TERMINAL_TITLE_INFO_LEVEL, varTerminalTitleInfoLevel);
    }

    varRunReplayTime = VarGetTime(VAR_RUN_REPLAY_TIME);
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

void TerminalTitleInfoLevelCallback(const uint index)
{
    varTerminalTitleInfoLevel = index;
    VarSetUint(VAR_TERMINAL_TITLE_INFO_LEVEL, varTerminalTitleInfoLevel);
}

const string TERMINAL_TITLE_TAG = "Incremental";

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


void Draw()
{
    if (modeIndex == 0)
    {
        const uint index = ModeIndexDetermineByName();
        if (index != 0 && !ModeIndexTrySet(index))
        {
            string s;
            s += "Loading: ";
            s += modeNames[index];
            s += CharRepeat(Time::Now % 4, '.');
            UI::TextWrapped(s);
        }
    }

    if (UI::CollapsingHeader("General"))
    {
        varEvalFullReplay = UI::CheckboxVar("Evaluate Full Replay", VAR_EVAL_FULL_REPLAY);
        TooltipOnHover(
            "Use the replay time (events duration) to determine the evaluation end time.\n"
            "This is mostly useful for e.g. Input Simplifier, where it makes sense to evaluate the full replay.");

        UI::BeginDisabled(varEvalFullReplay);

        varEvalIterBegin = UI::InputTimeVar("Evaluation Iteration Begin Time", VAR_EVAL_ITER_BEGIN);
        TooltipOnHover("The lower bound (inclusive) of iteration times.");

        if (mode.singleIteration)
        {
            varEvalIterEnd = varEvalIterBegin;
            VarSetTime(VAR_EVAL_ITER_END, varEvalIterEnd);

            UI::InputTime("Evaluation Iteration End Time", varEvalIterEnd);
            TooltipOnHover("The currently selected mode only supports a single iteration.");
        }
        else
        {
            varEvalIterEnd = UI::InputTime("Evaluation Iteration End Time", varEvalIterEnd);
            if (varEvalIterEnd < varEvalIterBegin)
                varEvalIterEnd = varEvalIterBegin;
            VarSetTime(VAR_EVAL_ITER_END, varEvalIterEnd);
            TooltipOnHover("The upper bound (inclusive) of iteration times.");
        }

        varEvalEnd = UI::InputTime("Evaluation End Time", varEvalEnd);
        if (varEvalEnd != 0 && varEvalEnd < varEvalIterEnd)
            varEvalEnd = varEvalIterEnd;
        VarSetTime(VAR_EVAL_END, varEvalEnd);
        TooltipOnHover(
            "If the input time is beyond this time, a new iteration is started.\n"
            "Set to 0 to have it be set to the events duration automatically.");

        UI::EndDisabled();

        UI::Separator();

        varUseSaveState = UI::CheckboxVar("Start from Save State", VAR_USE_SAVE_STATE);
        UI::BeginDisabled(!varUseSaveState);
        varSaveStateName = UI::InputTextVar("Save State name", VAR_SAVE_STATE_NAME);
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

void Initialize(SimulationManager@ sim, const ms alternativeTimeLimit)
{
    const uint index = ModeIndexDetermineByName();
    if (index == 0)
        log("Mode resolved to Home...?", Severity::Warning);
    ModeIndexTrySet(index);

    excludedInputTypesMask = EventIndicesMakeInputTypesBitmask(sim.InputEvents.EventIndices, mode.excludedInputTypes);

    VarsInit();

    ms evalIterBegin = 0;
    ms evalIterEnd   = 0;
    ms evalEnd       = 0;
    if (!varEvalFullReplay)
    {
        evalIterBegin = varEvalIterBegin;
        evalIterEnd   = varEvalIterEnd;
        evalEnd       = varEvalEnd;
    }

    tInit = evalIterBegin;
    tInput = -10; // Detecting uninitialized usage.
    tLimit = evalEnd != 0 ? evalEnd : alternativeTimeLimit;
    postInitIndex = uint(-1); // Detecting uninitialized usage.

    int resultsLen;
    if (mode.singleIteration)
    {
        resultsLen = 1;
    }
    else
    {
        resultsLen = (evalIterEnd - evalIterBegin) / 10 + 1;
        if (resultsLen < 1)
            resultsLen = 1;
    }
    results.Resize(resultsLen);
    resultIndex = 0;

    stepState = varUseSaveState ? StepState::SAVE_STATE : StepState::INIT;
    preventSimulationFinish = true;
    handleFinish = true;
}

void Begin(SimulationManager@ sim)
{
    if (varTerminalTitleInfoLevel == TerminalTitleInfoLevel::NONE)
        SetConsoleWindowTitle(TERMINAL_TITLE_TAG);

    string s;
    s += "\n\n-------- Incremental w/ ";
    s += modeNames[modeIndex];
    s += "\n";

    s += "Init Time: "; s += tInit; s += "ms\n";
    s += "Limit Time: "; s += tLimit; s += "ms\n";
    s += "Iterations: "; s += results.Length; s += "\n\n";

    s += "Use Save State: "; s += varUseSaveState; s += "\n";
    if (varUseSaveState)
    {
        s += "Save State Name: "; s += varSaveStateName; s += "\n";
    }
    s += "Print Extra Info: "; s += varPrintExtraInfo; s += "\n";
    s += "Terminal Title Info Level: "; s += TERMINAL_TITLE_INFO_LEVEL_NAMES[varTerminalTitleInfoLevel]; s += "\n";

    s += "\n";
    print(s);

    try
    {
        mode.begin(sim);
    }
    catch
    {
        PrintException("mode.begin");
        Finish(sim);
    }
}

void Iteration(SimulationManager@ sim)
{
    tInput = tInit + resultIndex * 10;
    postInitIndex = 0;
    PostInitInputEventsAdvance(sim.InputEvents);

    if (varTerminalTitleInfoLevel == TerminalTitleInfoLevel::ITERATION)
    {
        string s = TERMINAL_TITLE_TAG;
        TerminalTitleAppendIterationInfo(s);
        SetConsoleWindowTitle(s);
    }

    string s;
    s += "\n---- Iteration ";
    s += resultIndex + 1;
    s += " / ";
    s += results.Length;
    s += "\n";

    s += tInput;
    s += "ms -> ";
    s += tLimit;
    s += "ms\n";

    s += "\n";
    print(s);

    try
    {
        mode.iteration(sim);
    }
    catch
    {
        PrintException("mode.iteration");
        Finish(sim);
    }
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
            if (!stateFile.Load(varSaveStateName, error))
            {
                string s;
                s += "There was an error with the savestate:\n";
                s += error;
                print(s, Severity::Error);

                Finish(sim);
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

                Finish(sim);
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

        if (results.Length > 1)
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

                try
                {
                    mode.step(sim);
                }
                catch
                {
                    PrintException("mode.step");
                    Finish(sim);
                }

                break;
            }

            const ms checkTime = tLimit + 20;
            Assert(time <= checkTime);
            if (time != checkTime)
                break;
        }

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
    @initState = null;
    @inputState = null;
    postInitInputEvents.Clear();
    commitStates.Clear();
    commitAnalog.Clear();

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

    try
    {
        mode.end(sim);
    }
    catch
    {
        PrintException("mode.end");
        // NOTE: calling Finish here would mess up the state we just reset.
    }
}

void Finish(SimulationManager@ sim)
{
    handleFinish = false;

    stepState = StepState::FINISH;
    if (contextMode == ContextMode::Run)
        runState = RunState::END;

    if (results.Length == 1 && results[0] is null)
        @results[0] = Result(sim);
}

void PrintException(const string &in identifier)
{
    print("[Incremental] Exception caught: " + identifier, Severity::Error);
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
uint postInitIndex;
uint excludedInputTypesMask;

// Collect input events from IEB starting at the given index.
void PostInitInputEventsInitialize(const TM::InputEventBuffer@ ieb, const uint iebIndex)
{
    const uint iebLen = ieb.Length;
    Assert(iebLen >= iebIndex);

    postInitInputEvents.Resize(iebLen - iebIndex);
    for (uint i = iebIndex; i < iebLen; ++i)
        postInitInputEvents[i - iebIndex] = ieb[i];
}

// Add input events that are not excluded from the remainder of 'postInitInputEvents'.
void PostInitInputEventsFill(TM::InputEventBuffer@ ieb)
{
    const uint len = postInitInputEvents.Length;
    for (uint i = postInitIndex; i < len; ++i)
    {
        const TM::InputEvent inputEvent = postInitInputEvents[i];
        if (excludedInputTypesMask & 1 << inputEvent.Value.EventIndex == 0)
            ieb.Add(inputEvent);
    }
}

// Move 'postInitIndex' up to (but not including) input events < tInput, and adds those input events (without exclusion).
// Any input events >= tInput are filled like normal.
void PostInitInputEventsAdvance(TM::InputEventBuffer@ ieb)
{
    const uint len = postInitInputEvents.Length;
    const ums timestamp = IEB_TIME_OFFSET + tInput;
    for (; postInitIndex < len; ++postInitIndex)
    {
        const TM::InputEvent inputEvent = postInitInputEvents[postInitIndex];
        if (inputEvent.Time >= timestamp)
            break;

        ieb.Add(inputEvent);
    }
    PostInitInputEventsFill(ieb);
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


// NOTE: 'commitStates' is monotonically longer than 'commitAnalog'.
array<IncCommitState> commitStates;
array<int> commitAnalog;

IncCommitState StageGet(const InputType inputType, int &out analogValue)
{
    analogValue = 0;
    if (inputType == InputType::None)
        return IncCommitState::NONE;

    const uint index = inputType;
    if (index >= commitStates.Length)
        return IncCommitState::NONE;

    const IncCommitState state = commitStates[index];
    if (state == IncCommitState::SET)
        analogValue = commitAnalog[index];
    return state;
}

void StageSet(const InputType inputType, const int analogValue)
{
    if (inputType == InputType::None)
        return;

    AssertLog(inputType >= 0, "Tried to allocate a few GiB, do not pass negative values for inputType.");

    const uint index = inputType;
    if (index >= commitAnalog.Length)
    {
        commitAnalog.Resize(index + 1);
        if (index >= commitStates.Length)
            commitStates.Resize(index + 1);
    }

    commitStates[index] = IncCommitState::SET;
    commitAnalog[index] = analogValue;
}

void StageRemove(const InputType inputType)
{
    if (inputType == InputType::None)
        return;

    AssertLog(inputType >= 0, "Tried to allocate a few GiB, do not pass negative values for inputType.");

    const uint index = inputType;
    if (index >= commitStates.Length)
        commitStates.Resize(index + 1);

    commitStates[index] = IncCommitState::REMOVE;
}

void Commit(SimulationManager@ sim, const ms advance)
{
    AssertLog(advance % 10 == 0 && advance > 0, "Advance time must be a multiple of 10 greater than 0.");

    const ms time = tInput;
    tInput += advance;

    Rewind(sim, inputState, RewindFlags::REMOVE);
    PostInitInputEventsAdvance(sim.InputEvents);

    if (varTerminalTitleInfoLevel == TerminalTitleInfoLevel::COMMIT)
    {
        string s = TERMINAL_TITLE_TAG;
        TerminalTitleAppendIterationInfo(s);
        TerminalTitleAppendCommitInfo(s);
        SetConsoleWindowTitle(s);
    }

    string s;
    s += time;
    s += "ms\n";

    if (varPrintExtraInfo)
    {
        // NOTE: since we already did a rewind to inputState on this tick, we can access SimulationManager directly for stuff.
        const float mps = sim.Dyna.RefStateCurrent.LinearSpeed.Length();

        s += "Speed (km/h): ";
        s += FormatPrecise(mps * 3.6);
        s += "\n";
    }

    const uint len = commitStates.Length;
    for (uint i = 0; i < len; ++i)
    {
        const InputType type = InputType(i);
        int value;
        switch (StageGet(type, value))
        {
        case IncCommitState::NONE:
            // Do nothing.
            continue;
        case IncCommitState::SET:
            InputSet(sim, time, type, value);
            s += "+ ";
        break;
        case IncCommitState::REMOVE:
            InputRemove(sim, time, type);
            s += "- ";
        break;
        default:
            Unreachable();
        break;
        }

        InputCommand cmd;
        cmd.Timestamp = time;
        cmd.Type = type;
        cmd.State = value;
        s += cmd.ToString();
        s += "\n";
    }

    print(s);

    commitStates.Clear();
    commitAnalog.Clear();
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

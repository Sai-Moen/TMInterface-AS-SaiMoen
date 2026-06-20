namespace Core
{


const string VAR = "incremental_";

const string VAR_MODE = VAR + "mode";

const string VAR_EVAL_FULL_REPLAY      = VAR + "eval_full_replay";
const string VAR_EVAL_SINGLE_ITERATION = VAR + "eval_single_iteration";
const string VAR_EVAL_ITER_BEGIN       = VAR + "eval_iter_begin";
const string VAR_EVAL_ITER_END         = VAR + "eval_iter_end";
const string VAR_EVAL_END              = VAR + "eval_end";

const string VAR_USE_SAVE_STATE  = VAR + "use_save_state";
const string VAR_SAVE_STATE_NAME = VAR + "save_state_name";

const string VAR_PRINT_EXTRA_INFO          = VAR + "print_extra_info";
const string VAR_TERMINAL_TITLE_INFO_LEVEL = VAR + "terminal_title_info_level";

const string VAR_RUN_REPLAY_TIME  = VAR + "run_replay_time";
const string VAR_OPEN_RESULT_FILE = VAR + "open_result_file";

void VarsRegister()
{
    RegisterVariable(VAR_MODE, "");

    RegisterVariable(VAR_EVAL_FULL_REPLAY,      false);
    RegisterVariable(VAR_EVAL_SINGLE_ITERATION, false);
    RegisterVariable(VAR_EVAL_ITER_BEGIN,       0);
    RegisterVariable(VAR_EVAL_ITER_END,         0);
    RegisterVariable(VAR_EVAL_END,              0);

    RegisterVariable(VAR_USE_SAVE_STATE,  false);
    RegisterVariable(VAR_SAVE_STATE_NAME, "");

    RegisterVariable(VAR_PRINT_EXTRA_INFO,          true);
    RegisterVariable(VAR_TERMINAL_TITLE_INFO_LEVEL, 0);

    RegisterVariable(VAR_OPEN_RESULT_FILE, false);
    RegisterVariable(VAR_RUN_REPLAY_TIME,  0);
}

string varMode;

bool varEvalFullReplay;
bool varEvalSingleIteration;
ms varEvalIterBegin;
ms varEvalIterEnd;
ms varEvalEnd;

bool varUseSaveState;
string varSaveStateName;

bool varPrintExtraInfo;
uint varTerminalTitleInfoLevel;

ms varRunReplayTime;
bool varOpenResultFile;

void VarsInit()
{
    varMode = VarGetString(VAR_MODE);
    bool singleIteration = false;
    if (ModeDispatch())
        singleIteration = mode.singleIteration;

    varEvalFullReplay      = VarGetBool(VAR_EVAL_FULL_REPLAY);
    varEvalSingleIteration = VarGetBool(VAR_EVAL_SINGLE_ITERATION);

    varEvalIterBegin = VarGetTime(VAR_EVAL_ITER_BEGIN);
    if (varEvalIterBegin < 0)
    {
        varEvalIterBegin = 0;
        VarSetTime(VAR_EVAL_ITER_BEGIN, varEvalIterBegin);
    }

    varEvalIterEnd = VarGetTime(VAR_EVAL_ITER_END);
    if (varEvalIterEnd < varEvalIterBegin || singleIteration)
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

    varRunReplayTime  = VarGetTime(VAR_RUN_REPLAY_TIME);
    varOpenResultFile = VarGetBool(VAR_OPEN_RESULT_FILE);
}


enum TerminalTitleInfoLevel
{
    NONE,
    ITERATION,
    TIME,

    COUNT
}

const array<string> TERMINAL_TITLE_INFO_LEVEL_NAMES =
{
    "None",
    "Iteration",
    "Time"
};

void TerminalTitleInfoLevelCallback(const uint index)
{
    varTerminalTitleInfoLevel = index;
    VarSetUint(VAR_TERMINAL_TITLE_INFO_LEVEL, varTerminalTitleInfoLevel);
}

void TerminalTitleHandleNone()
{
    if (varTerminalTitleInfoLevel != TerminalTitleInfoLevel::NONE)
        return;

    SetConsoleWindowTitle(TERMINAL_TITLE_TAG);
}

void TerminalTitleHandleIteration()
{
    if (varTerminalTitleInfoLevel != TerminalTitleInfoLevel::ITERATION)
        return;

    string s = TERMINAL_TITLE_TAG;
    TerminalTitleAppendIterationInfo(s);
    SetConsoleWindowTitle(s);
}

void TerminalTitleHandleTime()
{
    if (varTerminalTitleInfoLevel != TerminalTitleInfoLevel::TIME)
        return;

    string s = TERMINAL_TITLE_TAG;
    TerminalTitleAppendIterationInfo(s);
    TerminalTitleAppendTimeInfo(s);
    SetConsoleWindowTitle(s);
}

const string TERMINAL_TITLE_TAG = "Incremental";

void TerminalTitleAppendIterationInfo(string& s)
{
    s += " | Iteration: ";
    s += resultIndex + 1;
    s += " / ";
    s += results.Length;
}

void TerminalTitleAppendTimeInfo(string& s)
{
    s += " | Time: ";
    s += lowerTime;
    s += "ms <= ";
    s += inputTime;
    s += "ms <= ";
    s += upperTime;
    s += "ms";
}


bool activateRunMode;

void Draw()
{
    if (UI::CollapsingHeader("General"))
    {
        varEvalFullReplay = UI::CheckboxVar("Evaluate Full Replay", VAR_EVAL_FULL_REPLAY);
        TooltipOnHover(
            "Use the replay time (events duration) to determine the evaluation end time.\n"
            "This is mostly useful for e.g. Input Simplifier, where it makes sense to evaluate the full replay.");

        UI::BeginDisabled(varEvalFullReplay);

        string singleIterationTooltip = "Evaluate a single iteration, rather than having a lower and upper bound.";
        if (mode.singleIteration)
        {
            VarSetBool(VAR_EVAL_SINGLE_ITERATION, true);
            singleIterationTooltip += "\nNOTE: the currently selected mode only supports a single iteration.";
        }
        varEvalSingleIteration = UI::CheckboxVar("Evaluate Single Iteration", VAR_EVAL_SINGLE_ITERATION);
        TooltipOnHover(singleIterationTooltip);

        if (varEvalSingleIteration)
        {
            varEvalIterBegin = UI::InputTimeVar("Evaluation Begin Time", VAR_EVAL_ITER_BEGIN);
            varEvalIterEnd = varEvalIterBegin;
            TooltipOnHover("The first timestamp for which inputs will be determined.");
        }
        else
        {
            varEvalIterBegin = UI::InputTimeVar("Evaluation Iteration Begin Time", VAR_EVAL_ITER_BEGIN);
            TooltipOnHover("The lower bound (inclusive) of iteration times.");

            varEvalIterEnd = UI::InputTime("Evaluation Iteration End Time", varEvalIterEnd);
            TooltipOnHover("The upper bound (inclusive) of iteration times.");

            if (varEvalIterEnd < varEvalIterBegin)
                varEvalIterEnd = varEvalIterBegin;
        }
        VarSetTime(VAR_EVAL_ITER_END, varEvalIterEnd);

        varEvalEnd = UI::InputTime("Evaluation End Time", varEvalEnd);
        if (varEvalEnd != 0 && varEvalEnd < varEvalIterEnd)
            varEvalEnd = varEvalIterEnd;
        VarSetTime(VAR_EVAL_END, varEvalEnd);

        if (varEvalSingleIteration)
        {
            TooltipOnHover("The last timestamp for which inputs will be determined.");
        }
        else
        {
            TooltipOnHover(
                "If the input time is beyond this time, a new iteration is started.\n"
                "Set to 0 to have it be set to the events duration automatically.");
        }

        UI::EndDisabled();

        UI::Separator();

        varUseSaveState = UI::CheckboxVar("Start from Save State", VAR_USE_SAVE_STATE);
        UI::BeginDisabled(!varUseSaveState);
        varSaveStateName = UI::InputTextVar("Save State name", VAR_SAVE_STATE_NAME);
        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Modes"))
    {
        ComboSelectName("Mode", modes.GetKeys(), varMode, ModeNameCallback);

        UI::Separator();
        UI::Separator();

        if (mode.draw !is null || ModeDispatch())
            mode.draw();
    }

    if (UI::CollapsingHeader("Run-Mode"))
    {
        UI::TextWrapped(
            "Run-Mode Bruteforce is an alternative to Simulation,"
            " where the plugin runs during a race rather than on a replay file.\n"
            "You should have your inputs loaded when using this.");

        UI::Separator();

        varRunReplayTime = UI::InputTimeVar("Replay Time", VAR_RUN_REPLAY_TIME);
        TooltipOnHover(
            "This is equivalent to the replay time (events duration) in Simulation.\n"
            "Inputs after this time will not be used!");

        varOpenResultFile = UI::CheckboxVar("Open Result File", VAR_OPEN_RESULT_FILE);
        TooltipOnHover(
            "Normally, the same script that was loaded before,"
            " will be re-loaded after the Run-Mode Bruteforce finished running.\n"
            "By enabling this setting, the result file will be loaded instead (if possible).");

        const CommandList@ const cmdlist = GetCurrentCommandList();
        UI::BeginDisabled(cmdlist is null);

        activateRunMode = UI::Checkbox("Activate Run-Mode Bruteforce", activateRunMode) && cmdlist !is null;
        TooltipOnHover("If this is checked while in run-mode, the plugin will start.");

        UI::EndDisabled();
    }

    if (UI::CollapsingHeader("Misc"))
    {
        varPrintExtraInfo = UI::CheckboxVar("Print Extra Info", VAR_PRINT_EXTRA_INFO);
        TooltipOnHover("Print additional information about the simulation to the bruteforce terminal.");

        ComboSelectIndex(
            "Terminal Title Info Level",
            TERMINAL_TITLE_INFO_LEVEL_NAMES,
            varTerminalTitleInfoLevel,
            TerminalTitleInfoLevelCallback);
        TooltipOnHover(
            "The level of information displayed in the (bruteforce) terminal title:\n"
            "- None: 'Incremental'.\n"
            "- Iteration: The current iteration number, compared to the total amount.\n"
            "- Time: The time at which the plugin currently is, compared to the lower and upper bounds.\n"
            "The TMInterface API documentation contains an ominous note about changing the terminal title too often,"
            " so perhaps the 'Time' mode has a noticable performance hit.");
    }
}


bool handleFinish;

void Initialize(SimulationManager@ sim, const ms alternativeTimeLimit)
{
    if (!ModeDispatch())
    {
        print("[Incremental] Could not dispatch to mode: " + varMode, Severity::Error);
        varMode = "";
        VarSetString(VAR_MODE, varMode);
        @mode = IncMode();
        Finish(sim);
        return;
    }

    ms evalIterBegin = 0;
    ms evalIterEnd   = 0;
    ms evalEnd       = 0;
    if (!varEvalFullReplay)
    {
        evalIterBegin = varEvalIterBegin;
        evalIterEnd   = varEvalIterEnd;
        evalEnd       = varEvalEnd;
    }

    baseTime = evalIterBegin - 10;
    upperTime = evalEnd != 0 ? evalEnd : alternativeTimeLimit;

    stepState = varUseSaveState ? StepState::SAVE_STATE : StepState::INIT;
    preventSimulationFinish = true;
    handleFinish = true;

    excludedEventIndicesMask = EventIndicesMakeInputTypesBitmask(sim.InputEvents.EventIndices, mode.excludedInputTypes);

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
}

void Begin(SimulationManager@ sim)
{
    TerminalTitleHandleNone();

    string s;
    s += "\n\n-------- Incremental w/ ";
    s += varMode;
    s += "\n";

    s += "Lower Time: "; s += lowerTime; s += "ms\n";
    s += "Upper Time: "; s += upperTime; s += "ms\n";
    s += "Iterations: "; s += results.Length; s += "\n\n";

    s += "Use Save State: "; s += varUseSaveState; s += "\n";
    if (varUseSaveState)
    {
        s += "Save State Name: "; s += varSaveStateName; s += "\n";
    }
    s += "Print Extra Info: "; s += varPrintExtraInfo; s += "\n";
    s += "Terminal Title Info Level: "; s += TERMINAL_TITLE_INFO_LEVEL_NAMES[varTerminalTitleInfoLevel]; s += "\n";
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
    trailTime = baseTime;
    @trailState = null;
    StageClear();

    lowerTime = (baseTime + 10) + resultIndex * 10;
    inputTime = lowerTime;

    {
        auto@ const ieb = sim.InputEvents;
        const ums timestamp = IEB_TIME_OFFSET + lowerTime;
        const uint len = postInitInputEvents.Length;
        for (postInitIndex = 0; postInitIndex < len; ++postInitIndex)
        {
            const TM::InputEvent inputEvent = postInitInputEvents[postInitIndex];
            if (inputEvent.Time >= timestamp)
                break;

            ieb.Add(inputEvent);
        }

        PostInitInputEventsFill(ieb);
    }

    TerminalTitleHandleIteration();

    string s;
    s += "\n---- Iteration ";
    s += resultIndex + 1;
    s += " / ";
    s += results.Length;
    s += "\n";

    s += lowerTime;
    s += "ms -> ";
    s += upperTime;
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
            if (stateFileTime > baseTime)
            {
                string s;
                s += "Attempted to load state that occurs too late! ";
                s += Time::Format(stateFileTime);
                s += " > ";
                s += Time::Format(baseTime);
                print(s, Severity::Error);

                Finish(sim);
                break;
            }

            sim.RewindToState(stateFile);
        }

        stepState = StepState::INIT;
    // fallthrough
    case StepState::INIT:
        {
            const ms time = sim.TickTime;
            if (time < baseTime)
                break;

            Assert(time == baseTime);
        }

        @baseState = sim.SaveState();

        Iteration(sim);
        stepState = StepState::STEP;
    // fallthrough
    case StepState::STEP:
        for (;;)
        {
            const ms time = sim.TickTime;
            if (inputTime <= upperTime)
            {
                if (time < inputTime)
                {
                    if (time == trailTime)
                        @trailState = sim.SaveState();

                    return;
                }

                if (time == inputTime)
                {
                    if (time != sim.RaceTime)
                        break;

                    @inputState = sim.SaveState();
                }

                try
                {
                    mode.step(sim);
                }
                catch
                {
                    PrintException("mode.step");
                    Finish(sim);
                }

                return;
            }

            if (time != sim.RaceTime)
                break;

            const ms checkTime = upperTime + 20;
            Assert(time <= checkTime);
            if (time != checkTime)
                return;

            // mfw no labelled blocks...
            break;
        }

        @results[resultIndex++] = Result(sim);
        if (resultIndex != results.Length)
        {
            Rewind(sim, baseState, RewindFlags::REMOVE);
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
    @baseState = null;
    @trailState = null;
    @inputState = null;
    postInitInputEvents.Clear();
    StageClear();

    stepState = StepState::NONE;
    preventSimulationFinish = false;
    handleFinish = false;

    CommandList script;

    const Result@ bestResult = results[0];
    if (bestResult is null)
    {
        script.Content = "# Incremental did not complete a pass.";
    }
    else
    {
        const uint len = results.Length;
        for (uint i = 1; i < len; ++i)
        {
            const Result@ const result = results[i];
            if (result is null)
                break;

            if (bestResult.time > result.time || bestResult.time == result.time && bestResult.metric < result.metric)
                @bestResult = result;
        }
        script.Content = bestResult.inputs;
    }
    results.Clear();
    resultIndex = 0;

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

    // As a failsafe, if we didn't get to the end of a single iteration run, just save the inputs.
    if (results.Length == 1 && results[0] is null)
        @results[0] = Result(sim);
}

void PrintException(const string &in identifier)
{
    print("[Incremental] Exception caught: " + identifier, Severity::Error);
}


dictionary modes;
const IncMode@ mode = IncMode();

bool ModeRegister(const string &in name, IncIMode@ imode)
{
    if (modes.Exists(name))
        return false;

    IncMode mode;

    mode.singleIteration    = imode.SingleIteration;
    mode.excludedInputTypes = imode.ExcludedInputTypes;

    @mode.draw = IncOnDraw(imode.Draw);

    @mode.begin     = IncOnBegin(imode.Begin);
    @mode.iteration = IncOnIteration(imode.Iteration);
    @mode.step      = IncOnStep(imode.Step);
    @mode.end       = IncOnEnd(imode.End);

    @modes[name] = mode;
    return true;
}

bool ModeRegister(const string &in name, IncMode mode)
{
    if (modes.Exists(name))
        return false;

    if (mode.draw is null) @mode.draw = function() {};

    if (mode.begin is null)     @mode.begin     = function(sim) {};
    if (mode.iteration is null) @mode.iteration = function(sim) {};
    if (mode.step is null)      @mode.step      = function(sim) {};
    if (mode.end is null)       @mode.end       = function(sim) {};

    @modes[name] = mode;
    return true;
}

void ModeNameCallback(const string &in name)
{
    if (ModeDispatch(name))
    {
        varMode = name;
        VarSetString(VAR_MODE, varMode);
    }
    else
    {
        string s;
        s += "Failed to dispatch, from mode: ";
        s += varMode;
        s += ", to mode: ";
        s += name;
        log(s, Severity::Warning);
    }
}

bool ModeDispatch(const string &in name = varMode)
{
    const IncMode@ m;
    const bool ok = modes.Get(name, @m);
    if (ok)
        @mode = m;
    return ok;
}


ms baseTime;  // The time required to ensure that we can run all iterations and/or revert.
ms trailTime; // The time of a cached save state, to speed up reverts.
ms inputTime; // The time currently being evaluated.
ms lowerTime; // The time at which the current iteration begins.
ms upperTime; // The time at which the current iteration ends.

SimulationState@ baseState;
SimulationState@ trailState;
SimulationState@ inputState;

array<TM::InputEvent> postInitInputEvents;
uint postInitIndex;
uint excludedEventIndicesMask;

// Collect input events from IEB starting at the given index.
void PostInitInputEventsInitialize(const TM::InputEventBuffer@ ieb, const uint iebIndex)
{
    const uint iebLen = ieb.Length;
    Assert(iebLen >= iebIndex);
    postInitInputEvents.Resize(iebLen - iebIndex);
    for (uint i = iebIndex; i < iebLen; ++i)
        postInitInputEvents[i - iebIndex] = ieb[i];
}

// Add input events that are not excluded, from the remainder of 'postInitInputEvents'.
void PostInitInputEventsFill(TM::InputEventBuffer@ ieb)
{
    const uint len = postInitInputEvents.Length;
    for (uint i = postInitIndex; i < len; ++i)
    {
        const TM::InputEvent inputEvent = postInitInputEvents[i];
        if (excludedEventIndicesMask & 1 << inputEvent.Value.EventIndex == 0)
            ieb.Add(inputEvent);
    }
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


// NOTE: 'stagedStates' is monotonically longer than 'stagedAnalog'.
array<IncStageState> stagedStates;
array<int> stagedAnalog;

IncStageState StageGet(const InputType inputType, int &out analogValue)
{
    analogValue = 0;
    if (inputType == InputType::None)
        return IncStageState::NONE;

    const uint index = inputType;
    if (index >= stagedStates.Length)
        return IncStageState::NONE;

    const IncStageState state = stagedStates[index];
    if (state == IncStageState::SET)
        analogValue = stagedAnalog[index];
    return state;
}

void StageSet(const InputType inputType, const int analogValue)
{
    if (inputType == InputType::None)
        return;

    AssertLog(inputType >= 0, "Tried to allocate a few GiB, do not pass negative values for inputType.");

    const uint index = inputType;
    if (index >= stagedAnalog.Length)
    {
        stagedAnalog.Resize(index + 1);
        if (index >= stagedStates.Length)
            stagedStates.Resize(index + 1);
    }

    stagedStates[index] = IncStageState::SET;
    stagedAnalog[index] = analogValue;
}

void StageRemove(const InputType inputType)
{
    if (inputType == InputType::None)
        return;

    AssertLog(inputType >= 0, "Tried to allocate a few GiB, do not pass negative values for inputType.");

    const uint index = inputType;
    if (index >= stagedStates.Length)
        stagedStates.Resize(index + 1);

    stagedStates[index] = IncStageState::REMOVE;
}

void StageClear()
{
    stagedStates.Clear();
    stagedAnalog.Clear();
}


void Forward(SimulationManager@ sim, const ms forward)
{
    const ms time = inputTime;
    inputTime += forward;

    Rewind(sim, inputState, RewindFlags::REMOVE);

    {
        PostInitInputEventsFill(sim.InputEvents);

        const ums timestamp = IEB_TIME_OFFSET + inputTime;
        const uint len = postInitInputEvents.Length;
        for (; postInitIndex < len; ++postInitIndex)
        {
            if (postInitInputEvents[postInitIndex].Time >= timestamp)
                break;
        }
    }

    TerminalTitleHandleTime();

    string s;
    s += "+ ";
    s += time;
    s += "ms\n";

    if (varPrintExtraInfo)
    {
        const float mps = sim.Dyna.RefStateCurrent.LinearSpeed.Length();

        s += "Speed (km/h): ";
        s += FormatPrecise(mps * 3.6);
        s += "\n";
    }

    const uint len = stagedStates.Length;
    for (uint i = 0; i < len; ++i)
    {
        const InputType type = InputType(i);
        int value;
        switch (StageGet(type, value))
        {
        case IncStageState::NONE:
            // Do nothing.
            continue;
        case IncStageState::SET:
            InputSet(sim, time, type, value);
            s += "+ ";
        break;
        case IncStageState::REMOVE:
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

    StageClear();
}

void Backward(SimulationManager@ sim, const ms backward, const ms cacheHint)
{
    inputTime -= backward;
    if (inputTime < lowerTime)
        inputTime = lowerTime;

    StageClear();

    {
        auto@ const ieb = sim.InputEvents;
        const ums timestamp = IEB_TIME_OFFSET + inputTime;
        IEBRemoveFromTimestamp(ieb, timestamp);

        while (postInitIndex > 0)
        {
            const uint before = postInitIndex - 1;
            if (postInitInputEvents[before].Time < timestamp)
                break;

            postInitIndex = before;
        }

        PostInitInputEventsFill(ieb);
    }

    SimulationState@ cachedState = baseState;
    if (trailTime >= inputTime)
    {
        trailTime = cacheHint > 10 ? inputTime - cacheHint : baseTime;
        @trailState = null;
    }
    else if (trailState !is null)
    {
        @cachedState = trailState;
    }

    Rewind(sim, cachedState, RewindFlags::PRESERVE);

    TerminalTitleHandleTime();

    string s;
    s += "- ";
    s += inputTime;
    s += "ms\n";
    print(s);
}


class Result
{
    ms time;
    float metric;
    string inputs;

    Result(SimulationManager@ sim)
    {
        time = sim.TickTime;
        metric = sim.Dyna.RefStateCurrent.LinearSpeed.LengthSquared();
        inputs = sim.InputEvents.ToCommandsText();
    }
}

array<Result@> results;
uint resultIndex;


} // namespace Core

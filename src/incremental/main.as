// Here TMInterface callbacks are implemented, along with their helpers.

const string ID = "incremental";
const string TITLE = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v2.1.1j";
    return info;
}

bool IsOtherController { get { return ID != GetVariableString("controller"); } }

void Main()
{
    Settings::RegisterSettings();

    IncRegisterMode("Home", Settings::Home());
    Eval::ModeDispatch();

    SpeedDrift::Main();
    Wallhugger::Main();
    InputSimplifier::Main();

    RegisterValidationHandler(ID, TITLE, Settings::RenderSettings);
    RegisterSettingsPage("Incremental Run-Mode", Settings::RenderRunMode);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsRunSimOnly)
    {
        Eval::Initialize(null);
    }
    else
    {
        if (IsOtherController)
            return;

        simManager.RemoveStateValidation();
        Eval::Initialize(simManager);
    }

    needToHandleCancel = true;
    onStep = Eval::IsUnlockedTimerange() ? OnStepState::RANGE_INIT : OnStepState::SINGLE;
    preventSimulationFinish = true;
    ignoreEnd = false;

    if (Eval::ShouldTryLoadingSaveState())
    {
        stateFilename = Settings::varSaveStateName;

        onStepTemp = onStep;
        onStep = OnStepState::SAVE_STATE;
    }

    Eval::ResolveModeIndex();
    print();
    print(TITLE + " w/ " + Eval::GetCurrentModeName());
    print();
    Eval::modeOnBegin(simManager);
}

enum OnStepState
{
    NONE,

    SAVE_STATE,
    SINGLE,
    RANGE_INIT, RANGE,

    COUNT
}

bool needToHandleCancel = false;

OnStepState onStep = OnStepState::NONE;
OnStepState onStepTemp = OnStepState::NONE;

string stateFilename;

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled)
    {
        if (needToHandleCancel)
        {
            Eval::SaveResult(simManager);
            Eval::Finish(simManager);
        }
        return;
    }

    const ms time = simManager.TickTime;
    switch (onStep)
    {
    case OnStepState::NONE:
        return;
    case OnStepState::SAVE_STATE:
        onStep = onStepTemp;
        {
            SimulationStateFile startStateFile;
            if (!startStateFile.CaptureCurrentState(simManager, true))
            {
                print("Could not capture current state while preparing recovery save state!", Severity::Error);
                break;
            }

            SimulationStateFile userStateFile;
            string error;
            if (!userStateFile.Load(stateFilename, error))
            {
                print("There was an error with the savestate:", Severity::Error);
                print(error, Severity::Error);
                break;
            }

            simManager.RewindToState(userStateFile);
            if (simManager.TickTime >= Eval::tInit) // TickTime here is not the same as 'time'
            {
                print("Attempted to load state that occurs too late! Reverting to start...", Severity::Warning);
                simManager.RewindToState(startStateFile);
                break;
            }
        }
        break;
    case OnStepState::SINGLE:
        if (Eval::tInput <= Eval::tLimit)
        {
            if (Eval::IsAtLeastInputTime(simManager))
                Eval::modeOnStep(simManager);
        }
        else
        {
            Eval::SaveResult(simManager);
            Eval::Finish(simManager);
        }
        break;
    case OnStepState::RANGE_INIT:
        if (Eval::IsInitTime(simManager))
            onStep = OnStepState::RANGE;
        break;
    case OnStepState::RANGE:
        if (Eval::tInput <= Eval::tLimit)
        {
            if (Eval::IsAtLeastInputTime(simManager))
                Eval::modeOnStep(simManager);
        }
        else
        {
            print(); // bit of spacing

            Eval::SaveResult(simManager);
            if (Eval::NextResult())
                Eval::PrepareResult(simManager);
            else
                Eval::Finish(simManager);
        }
        break;
    }
}

bool preventSimulationFinish = false;

void OnCheckpointCountChanged(SimulationManager@ simManager, int, int)
{
    if (preventSimulationFinish)
        simManager.PreventSimulationFinish();
}

bool ignoreEnd = true;

void OnSimulationEnd(SimulationManager@ simManager, SimulationResult)
{
    if (ignoreEnd)
        return;

    preventSimulationFinish = false;
    ignoreEnd = true;

    Eval::modeOnEnd(simManager);

    const string filename = GetVariableString("bf_result_filename");
    CommandList script;
    script.Content = Eval::GetBestInputs();
    if (script.Save(filename))
        print("Inputs saved! Filename: " + filename, Severity::Success);
    else
        print("Inputs not saved! Filename: " + filename, Severity::Error);

    Eval::Reset();
}

bool IsRunSimOnly { get { return soState != SimOnlyState::NONE; } }

enum SimOnlyState
{
    NONE,

    PRE_INIT, INIT, COLLECT,
    BEGIN, STEP, END,

    COUNT
}

SimOnlyState soState = SimOnlyState::NONE;

void OnRunStep(SimulationManager@ simManager)
{
    switch (soState)
    {
    case SimOnlyState::PRE_INIT:
        DrawGame(false);
        simManager.GiveUp();
        soState = SimOnlyState::INIT;
        break;
    case SimOnlyState::INIT:
        simManager.SimulationOnly = true;
        Eval::InitInputStates();
        preventSimulationFinish = true;
        soState = SimOnlyState::COLLECT;
        break;
    case SimOnlyState::COLLECT:
        Eval::CollectInputStates(simManager);
        if (simManager.TickTime > Eval::runReplayTime)
        {
            SetCurrentCommandList(null);
            simManager.SimulationOnly = false;
            simManager.GiveUp();
            soState = SimOnlyState::BEGIN;
        }
        break;
    case SimOnlyState::BEGIN:
        simManager.SimulationOnly = true;
        OnSimulationBegin(simManager);
        soState = SimOnlyState::STEP;
        break;
    case SimOnlyState::STEP:
        OnSimulationStep(simManager, false);
        Eval::ApplyInputStates(simManager);
        // state changes when Eval::Finish is called
        break;
    case SimOnlyState::END:
        OnSimulationEnd(simManager, SimulationResult::Valid);
        Eval::ResetInputStates();
        simManager.SimulationOnly = false;
        DrawGame(true);
        soState = SimOnlyState::NONE;
        break;
    }
}

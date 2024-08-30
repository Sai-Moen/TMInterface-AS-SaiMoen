// Here TMInterface callbacks are implemented, along with their helpers.

const string ID = "incremental";
const string TITLE = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v2.1.1f";
    return info;
}

bool IsOtherController()
{
    return ID != GetVariableString("controller");
}

void Main()
{
    Settings::RegisterSettings();

    IncRegisterMode("Home", Settings::Home());

    SpeedDrift::Main();
    Wallhugger::Main();
    InputSimplifier::Main();

    RegisterValidationHandler(ID, TITLE, Settings::RenderSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
        return;

    simManager.RemoveStateValidation();
    Eval::Initialize(simManager);

    needToHandleCancel = true;
    if (Eval::IsUnlockedTimerange())
    {
        onStep = OnStepState::RangeInit;
        Eval::InitializeInitTime();
    }
    else
    {
        onStep = OnStepState::Single;
    }
    preventSimulationFinish = true;
    ignoreEnd = false;

    if (Eval::ShouldTryLoadingSaveState())
    {
        stateFilename = Settings::varSaveStateName;

        onStepTemp = onStep;
        onStep = OnStepState::SaveState;
    }

    Eval::ModeDispatch();
    print();
    print(TITLE + " w/ " + Eval::GetCurrentModeName());
    print();
    Eval::modeOnBegin(simManager);
}

enum OnStepState
{
    None,

    SaveState,
    Single,
    RangeInit, Range,

    Count
}

bool needToHandleCancel = false;

OnStepState onStep = OnStepState::None;
OnStepState onStepTemp = OnStepState::None;

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
    case OnStepState::None:
        return;
    case OnStepState::SaveState:
        {
            const auto@ const start = simManager.SaveState();
            auto@ const scratchStateFile = SimulationStateFile();
            string error;
            if (scratchStateFile.Load(stateFilename, error))
            {
                simManager.RewindToState(scratchStateFile.ToState());
                if (simManager.TickTime >= Eval::tInit)
                {
                    print("Attempted to load state that occurs too late! Reverting to start...", Severity::Warning);
                    simManager.RewindToState(start);
                }
            }
            else
            {
                print("There was an error with the savestate:", Severity::Error);
                print(error, Severity::Error);
            }
        }
        onStep = onStepTemp;
        break;
    case OnStepState::Single:
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
    case OnStepState::RangeInit:
        if (Eval::IsInitTime(simManager))
            onStep = OnStepState::Range;
        break;
    case OnStepState::Range:
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

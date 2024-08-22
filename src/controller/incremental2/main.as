// Here TMInterface callbacks are implemented, along with their helpers.

const string ID = "incremental";
const string TITLE = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v2.1.1e";
    return info;
}

bool IsOtherController()
{
    return ID != GetVariableString("controller");
}

void Main()
{
    Settings::RegisterSettings();

    IncRegisterMode("Guide", Guide());

    //IncRegisterMode("SD Railgun", SD::Mode());
    //IncRegisterMode("Wallhugger", WH::Mode());
    //IncRegisterMode("Input Simplifier", SI::Mode());

    RegisterValidationHandler(ID, TITLE, Settings::RenderSettings);
}

void OnSimulationBegin(SimulationManager@ simManager)
{
    if (IsOtherController())
        return;

    simManager.RemoveStateValidation();

    if (Settings::varEvalEnd == 0)
        Eval::tLimit = simManager.EventsDuration;
    else
        Eval::tLimit = Settings::varEvalEnd;
    
    handledCancel = false;
    if (Settings::varLockTimerange)
    {
        onStep = OnStepState::Single;

        Eval::tInput = Settings::varEvalBeginStart;

        // TODO make sure there is space to store result
    }
    else
    {
        onStep = OnStepState::RangeInit;

        // TODO make sure there is space to store results
    }
    Eval::tState = Eval::tInput - TICK;
    preventSimulationFinish = true;
    ignoreEnd = false;

    if (Settings::varUseSaveState)
    {
        stateFilename = Settings::varSaveStateName;

        onStepTemp = onStep;
        onStep = OnStepState::SaveState;
    }

    ModeDispatch();
    print();
    print(TITLE + " w/ " + modeNames[modeIndex]);
    print();
    modeOnBegin(simManager);
}

enum OnStepState
{
    None,

    SaveState,
    Single,
    RangeInit, Range,

    Count
}

bool handledCancel = true;

string stateFilename;

OnStepState onStep = OnStepState::None;
OnStepState onStepTemp = OnStepState::None;

void OnSimulationStep(SimulationManager@ simManager, bool userCancelled)
{
    if (userCancelled)
    {
        if (handledCancel)
            return;

        Eval::Finish();
        return;
    }

    const ms time = simManager.TickTime;
    switch (onStep)
    {
    case OnStepState::SaveState:
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
        onStep = onStepTemp;
        break;
    case OnStepState::Single:
        // single timerange
    case OnStepState::RangeInit:
        if (Eval::IsBeforeInitTime(simManager))
            return;
        
        onStep = OnStepState::Range;
        break;
    case OnStepState::Range:
        // run through all times until they have been exhausted
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

    // handle End
}

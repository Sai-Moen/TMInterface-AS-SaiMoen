// Here TMInterface callbacks are implemented, along with their helpers.

const string ID = "incremental";
const string TITLE = "Incremental Controller";

PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = ID;
    info.Description = TITLE;
    info.Version = "v3.0.1";
    return info;
}

void Main()
{
    Settings::RegisterSettings();

    IncRegisterMode("Home", Settings::Home());
    Core::ModeDispatch();

    InputSimplifier::Main();
    SpeedDrift::Main();
    SteerMax::Main();
    Wallhugger::Main();

    RegisterValidationHandler(ID, TITLE, Settings::RenderSettings);
}

void OnSimulationBegin(SimulationManager@ sim)
{
    switch (contextMode)
    {
    case ContextMode::Simulation:
        if (ID != GetVariableString("controller"))
            return;

        sim.RemoveStateValidation();
        Core::Initialize(sim);
    break;
    case ContextMode::Run:
        Core::Initialize(null);
    break;
    default:
        PanicLog("Undefined ContextMode in OnSimulationBegin");
    break;
    }

    handleCancel = true;
    preventSimulationFinish = true;
    handleEnd = true;

    if (Core::ShouldTryLoadingSaveState())
    {
        saveStateName = Settings::varSaveStateName;
        onStep = OnStepState::SAVE_STATE;
    }
    else
    {
        onStep = OnStepState::INIT;
    }

    Core::ResolveModeIndex();

    string s;
    s += "\n";
    s += TITLE;
    s += " w/ ";
    s += Core::GetCurrentModeName();
    s += "\n\n";
    print(s);

    Core::modeOnBegin(sim);
}

enum OnStepState
{
    NONE,

    SAVE_STATE,
    INIT,
    MAIN,
}

bool finish;
bool handleFinish;

OnStepState onStep;

string saveStateName;

void OnSimulationStep(SimulationManager@ sim, bool userCancelled)
{
    if (userCancelled)
        finish = true;

    if (finish)
    {
        if (handleFinish)
            Core::Finish(sim);

        if (contextMode == ContextMode::Simulation)
            sim.ForceFinish();
        return;
    }

    const ms time = sim.TickTime;
    switch (onStep)
    {
    case OnStepState::NONE:
        // Not active.
    break;
    case OnStepState::SAVE_STATE:
        {
            SimulationStateFile startStateFile;
            if (!startStateFile.CaptureCurrentState(sim, true))
            {
                print("Could not capture current state while preparing recovery save state!", Severity::Error);
                break;
            }

            SimulationStateFile userStateFile;
            string error;
            if (!userStateFile.Load(saveStateName, error))
            {
                print("There was an error with the savestate:", Severity::Error);
                print(error, Severity::Error);
                break;
            }

            sim.RewindToState(userStateFile);
            // TickTime here is not the same as 'time', due to the rewind.
            if (sim.TickTime >= Core::tInit)
            {
                print("Attempted to load state that occurs too late! Reverting to start...", Severity::Warning);
                sim.RewindToState(startStateFile);
                break;
            }
        }
    break;
    case OnStepState::INIT:
        if (time < Core::tInit)
            break;

        Assert(time == Core::tInit);
        @Core::initState = sim.SaveState();
        onStep = OnStepState::MAIN;
    break;
    case OnStepState::MAIN:
        if (Core::tInput <= Core::tLimit)
        {
            if (time == Core::tTrail)
            {
                @Core::trailingState = sim.SaveState();
                break;
            }

            if (time < Core::tInput)
                break;

            if (speed == NO_SPEED && time == Core::tInput)
                speed = sim.Dyna.RefStateCurrent.LinearSpeed;

            Core::modeOnStep(sim);
        }
        else
        {
            print(); // bit of spacing

            Core::SaveResult(sim);
            if (Core::NextResult())
                Core::PrepareResult(sim);
            else
                Core::Finish(sim);
        }
    break;
    default:
        PanicLog("Undefined OnStepState in OnSimulationStep");
    break;
    }
}

bool preventSimulationFinish;

void OnCheckpointCountChanged(SimulationManager@ sim, int, int)
{
    if (preventSimulationFinish)
        sim.PreventSimulationFinish();
}

bool handleEnd;

void OnSimulationEnd(SimulationManager@ sim, SimulationResult)
{
    if (!handleEnd)
        return;

    finish = false;
    handleFinish = false;
    preventSimulationFinish = false;
    handleEnd = false;

    Core::modeOnEnd(sim);

    const string filename = GetVariableString("bf_result_filename");
    CommandList script;
    script.Content = Core::GetBestInputs();
    if (script.Save(filename))
        print("Inputs saved! Filename: " + filename, Severity::Success);
    else
        print("Inputs not saved! Filename: " + filename, Severity::Error);

    Core::Reset();
}

ContextMode contextMode;

enum SimOnlyState
{
    NONE,

    PRE_INIT, INIT, COLLECT,
    BEGIN, STEP, END
}

SimOnlyState soState;

void OnRunStep(SimulationManager@ sim)
{
    switch (soState)
    {
    case SimOnlyState::NONE:
        // Not active.
    break;
    case SimOnlyState::PRE_INIT:
        contextMode = ContextMode::Run;
        DrawGame(false);
        sim.GiveUp();
        soState = SimOnlyState::INIT;
    break;
    case SimOnlyState::INIT:
        sim.SimulationOnly = true;
        Core::InitInputStates();
        preventSimulationFinish = true;
        soState = SimOnlyState::COLLECT;
    break;
    case SimOnlyState::COLLECT:
        Core::CollectInputStates(sim);
        if (sim.TickTime > Core::runReplayTime)
        {
            SetCurrentCommandList(null);
            sim.SimulationOnly = false;
            sim.GiveUp();
            soState = SimOnlyState::BEGIN;
        }
    break;
    case SimOnlyState::BEGIN:
        sim.SimulationOnly = true;
        OnSimulationBegin(sim);
        soState = SimOnlyState::STEP;
    break;
    case SimOnlyState::STEP:
        OnSimulationStep(sim, false);
        Core::ApplyInputStates(sim);
        // state changes when Core::Finish is called
    break;
    case SimOnlyState::END:
        OnSimulationEnd(sim, SimulationResult::Valid);
        Core::ResetInputStates();
        sim.SimulationOnly = false;
        DrawGame(true);
        contextMode = ContextMode::Simulation;
        soState = SimOnlyState::NONE;
    break;
    default:
        PanicLog("Undefined SimOnlyState in OnRunStep");
    break;
    }
}

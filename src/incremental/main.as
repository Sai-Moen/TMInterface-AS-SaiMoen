PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = "Incremental";
    info.Description = "Incremental Controller";
    info.Version = "v3.0.1";
    return info;
}

const string ID = "incremental";
const string TITLE = "Incremental Controller";

void Main()
{
    Core::SettingsRegister();

    IncMode@ const home = Core::Home();
    IncRegisterMode("Home", home);
    @Core::mode = home;

    InputSimplifier::Main();
    SpeedDrift::Main();
    SteerMax::Main();
    Wallhugger::Main();

    RegisterValidationHandler(ID, TITLE, Core::SettingsRender);
}

void OnSimulationBegin(SimulationManager@ sim)
{
    if (ID != GetVariableString("controller"))
        return;

    sim.RemoveStateValidation();

    auto@ const buffer = sim.InputEvents;
    BufferRemoveEventIndex(buffer, buffer.EventIndices.FinishLineId);

    preventSimulationFinish = true;
    handleEnd = true;

    Core::Begin(sim);
}

enum StepState
{
    NONE,

    SAVE_STATE,
    INIT,
    ITER,
    STEP,
    FINISH,
}

StepState stepState;

void OnSimulationStep(SimulationManager@ sim, bool userCancelled)
{
    if (stepState == StepState::NONE)
        return;

    if (userCancelled)
        stepState = StepState::FINISH;

    Core::Step(sim);
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

    preventSimulationFinish = false;
    handleEnd = false;

    Core::End(sim);
}

ContextMode contextMode;

enum SimOnlyState
{
    NONE,

    INIT1, INIT2, COLLECT,
    BEGIN, STEP, END
}

SimOnlyState soState;

ms runReplayTime;
CommandList@ userCommandList;

void OnRunStep(SimulationManager@ sim)
{
    switch (soState)
    {
    case SimOnlyState::NONE:
        // Not active.
    break;
    case SimOnlyState::INIT1:
        contextMode = ContextMode::Run;

        DrawGame(false);
        preventSimulationFinish = true;
        sim.GiveUp();

        runReplayTime = VarGetMs(Core::VAR_RUN_REPLAY_TIME);
        soState = SimOnlyState::INIT2;
    break;
    case SimOnlyState::INIT2:
        // Messes with some game functionality like GiveUp, so it happens on a separate tick.
        sim.SimulationOnly = true;
        soState = SimOnlyState::COLLECT;
    break;
    case SimOnlyState::COLLECT:
        if (sim.TickTime <= runReplayTime)
            break;

        // TODO: preserve input events.
        @userCommandList = GetCurrentCommandList();
        SetCurrentCommandList(null);

        sim.SimulationOnly = false;
        sim.GiveUp();
        soState = SimOnlyState::BEGIN;
    break;
    case SimOnlyState::BEGIN:
        Core::Begin(sim);
        sim.SimulationOnly = true;
        soState = SimOnlyState::STEP;
    break;
    case SimOnlyState::STEP:
        Core::Step(sim);

        // Apply input events sitting in the Input Event Buffer (IEB).
        // Although the game would execute the input events normally, just like in Simulation Mode,
        // TMInterface doesn't understand what is going on if we just put them in the IEB in Run Mode (unfortunately).
        // We use SetInputState on all inputs at the current timestamp to ensure the inputs are actually played by TMInterface.
        ApplyInputEvents(sim);

        // The state changes when Core::Finish is called.
    break;
    case SimOnlyState::END:
        Core::End(sim);
        sim.SimulationOnly = false;

        SetCurrentCommandList(userCommandList);
        @userCommandList = null;

        preventSimulationFinish = false;
        DrawGame(true);

        contextMode = ContextMode::Simulation;
        soState = SimOnlyState::NONE;
    break;
    default:
        PanicLog("Undefined SimOnlyState in OnRunStep");
    break;
    }
}

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
    Settings::RegisterSettings();

    IncMode@ const home = Settings::Home();
    IncRegisterMode("Home", home);
    @Core::mode = home;

    InputSimplifier::Main();
    SpeedDrift::Main();
    SteerMax::Main();
    Wallhugger::Main();

    RegisterValidationHandler(ID, TITLE, Settings::RenderSettings);
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

enum OnStepState
{
    NONE,

    SAVE_STATE,
    INIT,
    MAIN,
    FINISH,
}

OnStepState onStep;

void OnSimulationStep(SimulationManager@ sim, bool userCancelled)
{
    if (onStep == OnStepState::None)
        return;

    if (userCancelled)
        onStep = OnStepState::FINISH;

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
        preventSimulationFinish = true;
        sim.SimulationOnly = true;
        soState = SimOnlyState::COLLECT;
    break;
    case SimOnlyState::COLLECT:
        // TODO: see also todo.md
        if (sim.TickTime > Core::runReplayTime)
        {
            // TODO save command list.
            SetCurrentCommandList(null);
            sim.SimulationOnly = false;
            sim.GiveUp();
            soState = SimOnlyState::BEGIN;
        }
    break;
    case SimOnlyState::BEGIN:
        sim.SimulationOnly = true;
        Core::Begin(sim);
        soState = SimOnlyState::STEP;
    break;
    case SimOnlyState::STEP:
        ApplyInputEvents(sim);
        Core::Step(sim);
        // The state changes when Core::Finish is called.
    break;
    case SimOnlyState::END:
        Core::End(sim);
        sim.SimulationOnly = false;
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

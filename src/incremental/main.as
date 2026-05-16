PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = "Incremental";
    info.Description = "Incremental Controller (Input Simplifier, SD, SteerMaximizer)";
    info.Version = "v3.1.0";
    return info;
}

const string ID = "incremental";

void Main()
{
    Core::Register();

    IncMode@ const home = Core::Home();
    IncRegisterMode("Home", home);
    @Core::mode = home;

    InputSimplifier::Main();
    SpeedDrift::Main();
    SteerMax::Main();
    Wallhugger::Main();

    RegisterValidationHandler(ID, "Incremental Controller", Core::Draw);
}

void OnSimulationBegin(SimulationManager@ sim)
{
    if (ID != GetVariableString("controller"))
        return;

    sim.RemoveStateValidation();

    auto@ const ieb = sim.InputEvents;
    IEBRemoveEventIndex(ieb, ieb.EventIndices.FinishLineId);

    Core::Initialize();
    Core::PostInitInputEventsInitialize(ieb);
    Core::Begin(sim);

    handleEnd = true;
}

enum StepState
{
    NONE,

    SAVE_STATE,
    INIT,
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

    handleEnd = false;
    Core::End(sim);
}

ContextMode contextMode;

enum RunState
{
    NONE,

    INIT1, INIT2, COLLECT,
    BEGIN, STEP, END
}

RunState runState;

ms runReplayTime;
CommandList@ userCommandList;
array<TM::InputEvent> preInitInputEvents;

void OnRunStep(SimulationManager@ sim)
{
    const ms time = sim.TickTime;
    switch (runState)
    {
    case RunState::NONE:
        // Not active.
    break;
    case RunState::INIT1:
        DrawGame(false);
        sim.GiveUp();
        contextMode = ContextMode::Run;

        Core::Initialize();
        runReplayTime = VarGetMs(Core::VAR_RUN_REPLAY_TIME);
        runState = RunState::INIT2;
    break;
    case RunState::INIT2:
        // Messes with some game functionality like GiveUp, so it happens on a separate tick.
        sim.SimulationOnly = true;
        runState = RunState::COLLECT;
    break;
    case RunState::COLLECT:
        if (time <= runReplayTime)
            break;

        @userCommandList = GetCurrentCommandList();
        SetCurrentCommandList(null);

        {
            const auto@ const ieb = sim.InputEvents;
            const uint iebIndex = IEBSearchTime(ieb, Core::tInit, -1);

            preInitInputEvents.Resize(iebIndex);
            for (uint i = 0; i < iebIndex; ++i)
                preInitInputEvents[i] = ieb[i];

            Core::PostInitInputEventsInitialize(ieb, iebIndex);
        }

        sim.SimulationOnly = false;
        sim.GiveUp();
        runState = RunState::BEGIN;
    break;
    case RunState::BEGIN:
        {
            auto@ const ieb = sim.InputEvents;
            const uint length = preInitInputEvents.Length;
            for (uint i = 0; i < length; ++i)
                ieb.Add(preInitInputEvents[i]);
            preInitInputEvents.Clear();

            Core::PostInitInputEventsCopyToIEB(ieb);
        }

        sim.SimulationOnly = true;
        Core::Begin(sim);
        runState = RunState::STEP;
    break;
    case RunState::STEP:
        Core::Step(sim);

        // Apply input events sitting in the Input Event Buffer (IEB).
        // Although the game would execute the input events normally, just like in Simulation Mode,
        // TMInterface doesn't understand what is going on if we just put them in the IEB in Run Mode (unfortunately).
        // We use SetInputState on all inputs at the current timestamp to ensure the inputs are actually played by TMInterface.
        ApplyInputEvents(sim);

        // The state changes when Core::Finish is called.
    break;
    case RunState::END:
        Core::End(sim);
        sim.SimulationOnly = false;

        SetCurrentCommandList(userCommandList);
        @userCommandList = null;

        contextMode = ContextMode::Simulation;
        DrawGame(true);
        runState = RunState::NONE;
    break;
    default:
        PanicLog("Undefined RunState in OnRunStep");
    break;
    }
}

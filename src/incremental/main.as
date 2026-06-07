PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = "Incremental";
    info.Description = "Incremental Controller (Input Simplifier, SD, SteerMaximizer)";
    info.Version = "v3.1.1";
    return info;
}

const string ID = "incremental";

void Main()
{
    Core::VarsRegister();
    Core::VarsInit();

    IncMode@ const home = Core::Home();
    IncRegisterMode("Home", home);
    @Core::mode = home;

    InputSimplifier::Main();
    SpeedDrift::Main();
    SteerMax::Main();

    RegisterValidationHandler(ID, "Incremental", Core::Draw);
}

void OnSimulationBegin(SimulationManager@ sim)
{
    if (ID != VarGetString("controller"))
        return;

    sim.RemoveStateValidation();

    auto@ const ieb = sim.InputEvents;
    IEBRemoveEventIndex(ieb, ieb.EventIndices.FinishLineId);

    Core::Initialize(sim, sim.EventsDuration);

    const uint iebIndex = IEBSearchTime(ieb, Core::initTime);
    Core::PostInitInputEventsInitialize(ieb, iebIndex);
    IEBRemoveFromIndex(ieb, iebIndex);

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

CommandList@ userCommandList;
array<TM::InputEvent> preInitInputEvents;

void OnRunStep(SimulationManager@ sim)
{
    const ms time = sim.TickTime;
    switch (runState)
    {
    case RunState::NONE:
        if (!Core::activateRunMode)
            break;

        Core::activateRunMode = false;
    // fallthrough
    case RunState::INIT1:
        DrawGame(false);
        sim.GiveUp();
        contextMode = ContextMode::Run;

        // Initialize calls VarsInit, but we already need this one to call Initialize with the correct alternative time limit.
        Core::varRunReplayTime = VarGetTime(Core::VAR_RUN_REPLAY_TIME);
        Core::Initialize(sim, Core::varRunReplayTime);
        runState = RunState::INIT2;
    break;
    case RunState::INIT2:
        // Messes with some game functionality like GiveUp, so it happens on a separate tick.
        sim.SimulationOnly = true;
        runState = RunState::COLLECT;
    break;
    case RunState::COLLECT:
        if (time <= Core::varRunReplayTime)
            break;

        @userCommandList = GetCurrentCommandList();
        SetCurrentCommandList(null);

        {
            const auto@ const ieb = sim.InputEvents;
            const uint iebIndex = IEBSearchTime(ieb, Core::initTime);

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

        {
            CommandList@ commandList = userCommandList;
            if (Core::varOpenResultFile)
            {
                const string filename = VarGetString("bf_result_filename");
                CommandList@ const resultCommandList = CommandListOpen(filename);
                if (resultCommandList !is null)
                {
                    resultCommandList.Process();
                    @commandList = resultCommandList;
                }
            }
            SetCurrentCommandList(commandList);
            @userCommandList = null;
        }

        contextMode = ContextMode::Simulation;
        DrawGame(true);
        runState = RunState::NONE;
    break;
    default:
        PanicLog("Undefined RunState in OnRunStep");
    break;
    }
}

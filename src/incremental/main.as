PluginInfo@ GetPluginInfo()
{
    PluginInfo info;
    info.Author = "SaiMoen";
    info.Name = "Incremental";
    info.Description = "Incremental Controller (Input Simplifier, SD, SteerMaximizer)";
    info.Version = "v3.2.1";
    return info;
}

const string ID = "incremental";

void Main()
{
    Core::VarsRegister();
    Core::VarsInit();

    RegisterValidationHandler(ID, "Incremental", Core::Draw);

    InputSimplifier::Main();
    SpeedDrift::Main();
    SteerMax::Main();
}

void OnSimulationBegin(SimulationManager@ sim)
{
    if (ID != VarGetString("controller"))
        return;

    sim.RemoveStateValidation();

    Core::VarsInit();
    Core::Initialize(sim, sim.EventsDuration);

    auto@ const ieb = sim.InputEvents;
    IEBSimplify(ieb);
    const uint iebIndex = IEBSearchTime(ieb, Core::baseTime);
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

    INIT, COLLECT,
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
        if (!Core::activateRunModeEvaluation)
            break;

        Core::activateRunModeEvaluation = false;

        DrawGame(false);
        sim.GiveUp();
        contextMode = ContextMode::Run;

        Core::VarsInit();
        Core::Initialize(sim, Core::varRunReplayTime);
        runState = RunState::INIT;
    break;
    case RunState::INIT:
        // Messes with some game functionality like GiveUp, so it happens on a separate tick.
        sim.SimulationOnly = true;
        runState = RunState::COLLECT;
    break;
    case RunState::COLLECT:
        Assert(time <= Core::varRunReplayTime);
        if (time != Core::varRunReplayTime)
            break;

        @userCommandList = GetCurrentCommandList();
        SetCurrentCommandList(null);

        {
            auto@ const ieb = sim.InputEvents;
            IEBSimplify(ieb);
            const uint iebIndex = IEBSearchTime(ieb, Core::baseTime);

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

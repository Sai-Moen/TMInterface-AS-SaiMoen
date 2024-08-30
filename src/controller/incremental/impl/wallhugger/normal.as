namespace Wallhugger::Normal
{


const string NAME = "Normal";

const string VAR = Wallhugger::VAR + "normal_";

const string INITIAL_STEER = VAR + "initial_steer";
int initialSteer;

const string SEEK_OFFSET = VAR + "seek_offset";
ms seekOffset;

const string TIMEOUT = VAR + "timeout";
const ms NO_TIMEOUT = 0;
ms timeout;

void RegisterSettings()
{
    RegisterVariable(INITIAL_STEER, STEER::FULL);
    RegisterVariable(SEEK_OFFSET, utils::TickToMs(20));
    RegisterVariable(TIMEOUT, 2000);

    initialSteer = int(GetVariableDouble(INITIAL_STEER));
    seekOffset = ms(GetVariableDouble(SEEK_OFFSET));
    timeout = ms(GetVariableDouble(TIMEOUT));
}

const string HELPFUL_TEXT = "Usually, you want to set this to " + STEER::MIN + " (left) or " + STEER::MAX + " (right).";

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        initialSteer = UI::SliderInt("Initial Steer", initialSteer, STEER::MIN, STEER::MAX);
        if (UI::Button("Left"))
            initialSteer = STEER::MIN;
        UI::SameLine();
        if (UI::Button("Right"))
            initialSteer = STEER::MAX;

        initialSteer = utils::ClampSteer(initialSteer);
        if (initialSteer == 0)
            initialSteer = 1;
        SetVariable(INITIAL_STEER, initialSteer);
        UI::TextWrapped(HELPFUL_TEXT);

        seekOffset = UI::InputTimeVar("Seek Offset", SEEK_OFFSET);
        UI::TextWrapped("This adds a certain amount of time to the wall detection time, the wall is avoided at the new time.");

        timeout = UI::InputTimeVar("Timeout", TIMEOUT);
        UI::TextWrapped("Timeout when looking for a wall (0 to disable).");
    }

    void OnBegin(SimulationManager@)
    {
        OnSimBegin();
    }

    void OnStep(SimulationManager@ simManager)
    {
        onStep(simManager);
    }

    void OnEnd(SimulationManager@)
    {}
}

funcdef bool Oob(const int);

bool hasTimeout;

int bound;
const Oob@ oob;

void OnSimBegin()
{
    hasTimeout = timeout != NO_TIMEOUT;

    switch (utils::Sign(initialSteer))
    {
    case utils::Signum::Negative:
        bound = STEER::MAX;
        @oob = function(nextSteer) { return nextSteer > bound; };
        break;
    case utils::Signum::Zero:
        print("Initial Steer should not be 0...", Severity::Error);
        @onStep = null; // bit of trolling
        return;
    case utils::Signum::Positive:
        bound = STEER::MIN;
        @oob = function(nextSteer) { return nextSteer < bound; };
        break;
    }

    Reset();
}

const OnSim@ onStep;

ms seek;

void OnStepScan(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    if (time == 0)
    {
        IncSetInput(simManager, InputType::Steer, steer);
        return;
    }

    if (HasCrashed(simManager))
    {
        seek = time + seekOffset;
        @onStep = OnStepMain;
    }
    else if (hasTimeout && time >= timeout)
    {
        CommitSteer(simManager, initialSteer);
    }
    else
    {
        return;
    }

    IncRewind(simManager);
}

void OnStepMain(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    if (time == 0)
    {
        IncSetInput(simManager, InputType::Steer, steer);
    }
    else if (time == seek)
    {
        OnEval(simManager);
        IncRewind(simManager);
    }
}

int prevSteer;
int step;

void OnEval(SimulationManager@ simManager)
{
    const int nextSteer = steer + step;
    if (oob(nextSteer))
    {
        prevSteer = steer;
        step >>>= 1;
    }
    else
    {
        if (HasCrashed(simManager))
        {
            prevSteer = steer;
            steer = nextSteer;
        }
        else
        {
            step >>>= 1;
            if (step != 0)
                steer = prevSteer;
        }
    }

    if (step == 0)
        CommitSteer(simManager, steer);
}

void CommitSteer(SimulationManager@ simManager, const int steer)
{
    IncCommitContext ctx;
    ctx.steer = steer;
    IncCommit(simManager, ctx);
    Reset();
}

void Reset()
{
    steer = initialSteer;
    prevSteer = steer;
    step = bound;

    @onStep = OnStepScan;
}

bool HasCrashed(SimulationManager@ simManager)
{
    const auto@ const svcOld = IncGetTrailingState().SceneVehicleCar;
    const auto@ const svcNew = simManager.SceneVehicleCar;
    return svcNew.LastHasAnyLateralContactTime != svcOld.LastHasAnyLateralContactTime;
}


} // namespace Wallhugger::Normal

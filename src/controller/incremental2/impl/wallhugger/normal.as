namespace Wallhugger::Normal
{


const string VAR = Wallhugger::VAR + "normal_";

const string INITIAL_STEER = VAR + "initial_steer";
int initialSteer;

const string SEEK_OFFSET = VAR + "seek_offset";
ms seekOffset;

const string TIMEOUT = VAR + "timeout";
const ms NO_TIMEOUT = 0;
ms timeout;

void OnRegister()
{
    RegisterVariable(INITIAL_STEER, STEER::FULL);
    RegisterVariable(SEEK_OFFSET, TickToMs(10));
    RegisterVariable(TIMEOUT, 2000);

    initialSteer = int(GetVariableDouble(INITIAL_STEER));
    seekOffset = ms(GetVariableDouble(SEEK_OFFSET));
    timeout = ms(GetVariableDouble(TIMEOUT));
}

const string HELPFUL_TEXT = "Usually, you want to set this to " + STEER::MIN + " (left) or " + STEER::MAX + " (right).";

void OnSettings()
{
    UI::Separator();

    if (UI::Button("Left"))
        initialSteer = STEER::MIN;
    UI::SameLine();
    initialSteer = UI::SliderInt("Initial Steer", initialSteer, STEER::MIN, STEER::MAX);
    UI::SameLine();
    if (UI::Button("Right"))
        initialSteer = STEER::MAX;

    initialSteer = ClampSteer(initialSteer);
    if (initialSteer == 0)
        initialSteer = 1;
    SetVariable(INITIAL_STEER, initialSteer);
    UI::TextWrapped(HELPFUL_TEXT);

    UI::Separator();

    seekOffset = UI::InputTimeVar("Seek Offset", SEEK_OFFSET);
    UI::TextWrapped("This adds a certain amount of time to the wall detection time, the wall is avoided at the new time.");

    UI::Separator();

    timeout = UI::InputTimeVar("Timeout", TIMEOUT);
    UI::TextWrapped("Timeout when looking for a wall (0 to disable).");
}

funcdef bool Oob(const int);

bool hasTimeout;

int bound;
const Oob@ oob;

void OnBegin(SimulationManager@)
{
    hasTimeout = timeout != NO_TIMEOUT;

    switch (Sign(initialSteer))
    {
    case Signum::Negative:
        bound = STEER::MAX;
        @oob = function(nextSteer) { return nextSteer > bound; };
        break;
    case Signum::Zero:
        print("Initial Steer should not be 0...", Severity::Error);
        @onStep = null; // bit of trolling
        return;
    case Signum::Positive:
        bound = STEER::MIN;
        @oob = function(nextSteer) { return nextSteer < bound; };
        break;
    }

    Reset();
}

const OnSim@ onStep;

void OnStep(SimulationManager@ simManager)
{
    onStep(simManager);
}

void OnStepScan(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    const ms diff = time - Eval::Time::Input;
    if (simManager.SceneVehicleCar.HasAnyLateralContact)
    {
        const ms seek = diff + seekOffset;
        Eval::Time::OffsetEval(seek);
        @onStep = OnStepMain;
    }
    else if (hasTimeout && diff >= timeout)
    {
        Advance(simManager, initialSteer);
    }
    else
    {
        Eval::AddInput(simManager, time, InputType::Steer, initialSteer);
        return;
    }

    Eval::Rewind(simManager);
}

void OnStepMain(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (Eval::IsEvalTime(time))
    {
        OnEval(simManager);
        Eval::Rewind(simManager);
    }
    else
    {
        Eval::AddInput(simManager, time, InputType::Steer, steer);
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
        const bool hasCrashed =
            simManager.SceneVehicleCar.LastHasAnyLateralContactTime !=
            Eval::MinState.SceneVehicleCar.LastHasAnyLateralContactTime;
        if (hasCrashed)
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
        Advance(simManager, steer);
}

void Advance(SimulationManager@ simManager, const int steer)
{
    Eval::Advance(simManager, steer);
    Reset();
}

void Reset()
{
    steer = initialSteer;
    prevSteer = steer;
    step = bound;

    @onStep = OnStepScan;
}


} // namespace Wallhugger::Normal

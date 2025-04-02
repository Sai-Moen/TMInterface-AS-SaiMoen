namespace Wallhugger::Classic
{


const string NAME = "Classic";

const string VAR = Wallhugger::VAR + "classic_";

const string SEEK = VAR + "seek";
const ms DEFAULT_SEEK = 600;
ms seek;

const string DIRECTION = VAR + "direction";
const float MAX_VEL_LOSS = 0.002; // per ms
string directionStr;

void RegisterSettings()
{
    RegisterVariable(SEEK, DEFAULT_SEEK);
    RegisterVariable(DIRECTION, directions[0]);

    seek = ms(GetVariableDouble(SEEK));
    directionStr = GetVariableString(DIRECTION);
    direction = directions[0] == directionStr ? Direction::left : Direction::right;
}

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
        ComboHelper("Direction", directions, directionStr, ChangeDirection);
    }

    void OnBegin(SimulationManager@)
    {
        OnSimBegin();
    }

    void OnStep(SimulationManager@ simManager)
    {
        OnSimStep(simManager);
    }

    void OnEnd(SimulationManager@)
    {}
}

enum Direction
{
    left = -1,
    right = 1,
}

Direction direction;
const array<string> directions = { "Left", "Right" };

void ChangeDirection(const string &in newMode)
{
    direction = directions[0] == newMode ? Direction::left : Direction::right;
    directionStr = newMode;
}

float maxVelocityLoss;

int avoider;
int collider;

void OnSimBegin()
{
    if (seek < TICK)
        seek = TICK;
    maxVelocityLoss = seek * MAX_VEL_LOSS;
    Reset();
}

void OnSimStep(SimulationManager@ simManager)
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

void OnEval(SimulationManager@ simManager)
{
    if (HasCrashed(simManager))
        collider = steer;
    else
        avoider = steer;

    if (Math::Abs(avoider - collider) > 1)
    {
        steer = (avoider + collider) >>> 1;
    }
    else
    {
        IncCommitContext ctx;
        ctx.steer = avoider;
        IncCommit(simManager, ctx);
        Reset();
    }
}

void Reset()
{
    avoider = STEER_MIN * direction;
    collider = STEER_MAX * direction;
    steer = collider;
}

bool HasCrashed(SimulationManager@ simManager)
{
    const auto@ const svcOld = IncGetTrailingState().SceneVehicleCar;
    const auto@ const svcNew = simManager.SceneVehicleCar;
    return
        svcNew.LastHasAnyLateralContactTime != svcOld.LastHasAnyLateralContactTime ||
        svcNew.CurrentLocalSpeed.Length() < (svcOld.CurrentLocalSpeed.Length() - maxVelocityLoss);
}


} // namespace Wallhugger::Classic

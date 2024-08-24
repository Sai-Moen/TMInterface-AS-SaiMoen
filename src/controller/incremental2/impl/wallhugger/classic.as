namespace Wallhugger::Classic
{


const string VAR = Wallhugger::VAR + "classic_";

const string SEEK = VAR + "seek";
const ms DEFAULT_SEEK = 600;
ms seek;

const string DIRECTION = VAR + "direction";
const float MAX_VEL_LOSS = 0.002; // per ms
string directionStr;

void OnRegister()
{
    RegisterVariable(SEEK, DEFAULT_SEEK);
    RegisterVariable(DIRECTION, directions[0]);

    seek = ms(GetVariableDouble(SEEK));
    directionStr = GetVariableString(DIRECTION);
    direction = directions[0] == directionStr ? Direction::left : Direction::right;
}

enum Direction
{
    left = -1,
    right = 1,
}

Direction direction;
const array<string> directions = {"Left", "Right"};

void OnSettings()
{
    seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
    ComboHelper("Direction", directionStr, directions, ChangeMode);
}

void ChangeMode(const string &in newMode)
{
    direction = directions[0] == newMode ? Direction::left : Direction::right;
    directionStr = newMode;
}

float maxVelocityLoss;

int avoider;
int collider;

void OnBegin(SimulationManager@)
{
    maxVelocityLoss = seek * MAX_VEL_LOSS;
    Reset();
}

void OnStep(SimulationManager@ simManager)
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

void OnEval(SimulationManager@ simManager)
{
    const auto@ const svcNew = simManager.SceneVehicleCar;
    const auto@ const svcOld = Eval::MinState.SceneVehicleCar;

    const bool crashed =
        svcNew.LastHasAnyLateralContactTime != svcOld.LastHasAnyLateralContactTime ||
        svcNew.CurrentLocalSpeed.Length() < (svcOld.CurrentLocalSpeed.Length() - maxVelocityLoss);
    if (crashed)
        collider = steer;
    else
        avoider = steer;

    const bool isDone = Math::Abs(avoider - collider) <= 1;
    if (isDone)
    {
        Eval::Advance(simManager, avoider);
        Reset();
    }
    else
    {
        steer = (avoider + collider) >>> 1;
    }
}

void Reset()
{
    Eval::Time::OffsetEval(seek);

    avoider = STEER::MIN * direction;
    collider = STEER::MAX * direction;
    steer = collider;
}


} // namespace Wallhugger::Classic

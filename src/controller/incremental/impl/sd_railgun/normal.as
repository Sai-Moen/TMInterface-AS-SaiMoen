namespace SpeedDrift::Normal
{


const string NAME = "Normal";

const string VAR = SpeedDrift::VAR + "normal_";

const string SEEK = VAR + "seek";
ms seek;

void RegisterSettings()
{
    RegisterVariable(SEEK, 120);
    seek = ms(GetVariableDouble(SEEK));
}

class Mode : IncMode
{
    bool SupportsUnlockedTimerange { get { return true; } }

    void RenderSettings()
    {
        seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
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

void OnSimBegin()
{
    if (seek < TICK)
        seek = TICK;
    Reset();
}

const OnSim@ onStep;

const int RANGE_SIZE = 4;

const int STEP_DONE = -1;
const int STEP_LAST_DEVIATION = RANGE_SIZE / 2;

int step;

void OnStepInit(SimulationManager@ simManager)
{
    const float prevTurningRate = IncGetTrailingState().SceneVehicleCar.TurningRate;
    const float turningRate = simManager.SceneVehicleCar.TurningRate;
    bestSteer = utils::RoundAway(turningRate * STEER::FULL, turningRate - prevTurningRate);

    step = 0x8000 / RANGE_SIZE;
    SetRangeAroundMidpoint(bestSteer);

    @onStep = OnStepMain;
    onStep(simManager);
}

void OnStepMain(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    if (time == 0)
    {
        while (!range.Done)
        {
            steer = range.Iter();
            if (triedSteers.Find(steer) == -1)
            {
                triedSteers.Add(steer);
                IncSetInput(simManager, InputType::Steer, steer);
                break;
            }
        }
    }
    else if (time == seek)
    {
        OnEval(simManager);
        IncRewind(simManager);
    }
}

void OnEval(SimulationManager@ simManager)
{
    const double result = simManager.Dyna.RefStateCurrent.LinearSpeed.Length();
    if (bestResult < result)
    {
        bestResult = result;
        bestSteer = steer;
    }

    if (!range.Done)
        return;

    switch (step)
    {
    case STEP_DONE:
        {
            IncCommitContext ctx;
            ctx.steer = bestSteer;
            IncCommit(simManager, ctx);
        }
        Reset();
        break;
    case 0:
    case 1:
        step = STEP_DONE;
        range = utils::RangeIncl(bestSteer - STEP_LAST_DEVIATION, bestSteer + STEP_LAST_DEVIATION, 1);
        break;
    default:
        step >>= 1;
        SetRangeAroundMidpoint(bestSteer);
        break;
    }
}

void Reset()
{
    triedSteers.Clear();
    bestResult = -1;

    @onStep = OnStepInit;
}

void SetRangeAroundMidpoint(const int midpoint)
{
    const int offset = step * (RANGE_SIZE - 1) / 2;
    range = utils::RangeIncl(midpoint - offset, midpoint + offset, step);
}


} // namespace SpeedDrift::Normal

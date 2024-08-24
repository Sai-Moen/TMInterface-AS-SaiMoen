namespace SpeedDrift::Normal
{


const string VAR = SpeedDrift::VAR + "normal_";

const string SEEK = VAR + "seek";
ms seek;

void OnRegister()
{
    RegisterVariable(SEEK, 120);
    seek = ms(GetVariableDouble(SEEK));
}

void OnSettings()
{
    seek = UI::InputTimeVar("Seeking (lookahead) time", SEEK, TICK);
}

const int RANGE_SIZE = 4;

const int STEP_DONE = -1;
const int STEP_LAST_DEVIATION = RANGE_SIZE / 2;

const OnSim@ onStep;

void OnBegin(SimulationManager@)
{
    Reset();
}

void OnStep(SimulationManager@ simManager)
{
    onStep(simManager);
}

int step;

void OnStepPre(SimulationManager@ simManager)
{
    const float prevTurningRate = Eval::MinState.SceneVehicleCar.TurningRate;
    const float turningRate = simManager.SceneVehicleCar.TurningRate;
    bestSteer = RoundAway(turningRate * STEER::FULL, turningRate - prevTurningRate);

    step = 0x8000 / RANGE_SIZE;
    SetRangeAroundMidpoint(bestSteer);

    @onStep = OnStepMain;
    onStep(simManager);
}

void OnStepMain(SimulationManager@ simManager)
{
    const ms time = simManager.TickTime;
    if (Eval::IsInputTime(time))
    {
        while (!range.Done)
        {
            steer = range.Iter();
            if (triedSteers.Find(steer) == -1)
            {
                triedSteers.Add(steer);
                break;
            }
        }
    }
    
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
    const double result = simManager.Dyna.RefStateCurrent.LinearSpeed.Length();
    if (result > bestResult)
    {
        bestResult = result;
        bestSteer = steer;
    }

    if (!range.Done)
        return;

    switch (step)
    {
    case STEP_DONE:
        Eval::Advance(simManager, bestSteer);
        Reset();
        break;
    case 0:
    case 1:
        step = STEP_DONE;
        range = RangeIncl(bestSteer - STEP_LAST_DEVIATION, bestSteer + STEP_LAST_DEVIATION, 1);
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

    Eval::Time::OffsetEval(seek);
    @onStep = OnStepPre;
}

void SetRangeAroundMidpoint(const int midpoint)
{
    const int offset = step * (RANGE_SIZE - 1) / 2;
    range = RangeIncl(midpoint - offset, midpoint + offset, step);
}


} // namespace SpeedDrift::Normal

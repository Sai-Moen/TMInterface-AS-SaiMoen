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
const int STEP_LAST_DEVIATION = RANGE_SIZE / 2;

int step;
bool done;

void OnStepInit(SimulationManager@ simManager)
{
    const float prevTurningRate = IncGetTrailingState().SceneVehicleCar.TurningRate;
    const float turningRate = simManager.SceneVehicleCar.TurningRate;
    bestSteer = RoundAway(turningRate * STEER_FULL, turningRate - prevTurningRate);
    bestResult = -1;

    step = 0x8000 / RANGE_SIZE;
    SetSteerBounds();
    done = false;

    @onStep = OnStepMain;
    onStep(simManager);
}

void OnStepMain(SimulationManager@ simManager)
{
    const ms time = IncGetRelativeTime(simManager);
    if (time == 0)
    {
        while (steer <= bound)
        {
            steer += step;
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

    if (steer <= bound)
        return;

    if (done)
    {
        IncCommitContext ctx;
        ctx.steer = bestSteer;
        IncCommit(simManager, ctx);

        Reset();
        return;
    }

    switch (step)
    {
    case 0:
        print("step == 0", Severity::Warning);
        step = 1;
        // fallthrough
    case 1:
        SetSteerBoundsWithOffset(STEP_LAST_DEVIATION);
        done = true;
        break;
    default:
        step >>= 1;
        SetSteerBounds();
        break;
    }
}

// Note: relies on side-effect from step
void SetSteerBounds()
{
    SetSteerBoundsWithOffset(step * (RANGE_SIZE - 1) / 2);
}

void SetSteerBoundsWithOffset(const int offset)
{
    steer = ClampSteer(bestSteer - offset);
    bound = ClampSteer(bestSteer + offset);
}

void Reset()
{
    triedSteers.Clear();
    @onStep = OnStepInit;
}


} // namespace SpeedDrift::Normal
